import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:fnes/components/audio_manager.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cartridge.dart';
import 'package:fnes/components/emulator_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals_flutter.dart';

enum RenderMode {
  both('Background & Sprites'),
  background('Background'),
  sprites('Sprites');

  const RenderMode(this.label);

  final String label;
}

class NESEmulatorController {
  NESEmulatorController({required this.bus}) {
    bus.setSampleFrequency(44100);
    unawaited(_initializeAudio());
  }

  final Bus bus;
  final StreamController<Image> _imageStreamController =
      StreamController<Image>.broadcast();

  static const int _maxFrameSkip = 0;
  static const double _targetFrameTimeMs = 1000.0 / 60.0;

  final Signal<bool> isRunning = signal(false);
  final Signal<bool> isROMLoaded = signal(false);
  final Signal<String?> romFileName = signal<String?>(null);
  final Signal<Image?> screenImage = signal<Image?>(null);
  final Signal<FilterQuality> filterQuality =
      signal<FilterQuality>(FilterQuality.none);
  final Signal<bool> isDebuggerVisible = signal(true);
  final Signal<bool> isOnScreenControllerVisible = signal(false);
  final Signal<double> currentFPS = signal(0);
  final Signal<bool> audioEnabled = signal(true);
  final Signal<bool> uncapFramerate = signal(false);
  final Signal<RenderMode> renderMode = signal(RenderMode.both);

  final Signal<bool> isLoadingROM = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);

  final Signal<int> frameUpdateTrigger = signal(0);

  final Signal<bool> isRewinding = signal(false);
  final Signal<double> rewindProgress = signal(0);
  final Signal<bool> rewindEnabled = signal(false);
  final RewindBuffer _rewindBuffer = RewindBuffer();
  int _statesSavedSinceLastFrame = 0;
  static const int _saveStateEveryNFrames = 1;

  final Signal<bool> hasSaveState = signal(false);

  late final Computed<String?> romName = computed(() {
    final fileName = romFileName.value;
    return fileName?.split('.').first;
  });

  int _frameCount = 0;
  int _skipFrames = 0;
  DateTime _lastFPSUpdate = DateTime.now();
  late DateTime _lastFrameTime;

  final Stopwatch _frameStopwatch = Stopwatch();

  final AudioManager _audioPlayer = AudioManager();

  Stream<Image> get imageStream => _imageStreamController.stream;

  Future<void> _initializeAudio() async => _audioPlayer.initialize();

  Future<Image> _createScreenImage(Uint8List pixelBuffer) async {
    final completer = Completer<Image>();

    decodeImageFromPixels(
      pixelBuffer,
      256,
      240,
      PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  Future<void> updatePixelBuffer() async {
    const width = 256;
    const height = 240;

    final buffer32 = Uint32List(width * height);
    final romLoaded = isROMLoaded.value && bus.cart != null;
    final pal = _colorPalette;

    for (var y = 0; y < height; y++) {
      final row = bus.ppu.screenPixels[y];
      final offset = y * width;

      if (!romLoaded) {
        buffer32.fillRange(offset, offset + width, pal[0]);

        continue;
      }

      final row32 = row.map((i) => pal[i]).toList();

      buffer32.setRange(offset, offset + width, row32);
    }

    final pixelBuffer = buffer32.buffer.asUint8List();
    final image = await _createScreenImage(pixelBuffer);

    screenImage.value = image;
    frameUpdateTrigger.value = (frameUpdateTrigger.value + 1) % 60000;

    if (!_imageStreamController.isClosed) {
      _imageStreamController.add(image);
    }
  }

  late final Uint32List _colorPalette = Uint32List.fromList(
    bus.ppu.palScreen.map((color) {
      final r = (color.r * 255).toInt();
      final g = (color.g * 255).toInt();
      final b = (color.b * 255).toInt();

      return (255 << 24) | (b << 16) | (g << 8) | r;
    }).toList(),
  );

  Future<void> loadROMFile() async {
    try {
      isLoadingROM.value = true;
      errorMessage.value = null;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['nes'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final cart = Cartridge.fromBytes(file.bytes!);

          if (cart.imageValid()) {
            bus
              ..insertCartridge(cart)
              ..reset();

            clearRewindBuffer();

            isROMLoaded.value = true;
            romFileName.value = file.name;
            unawaited(_checkSaveStateExists());
            startEmulation();
          } else {
            errorMessage.value = 'Invalid ROM file format';
          }
        }
      }

      isLoadingROM.value = false;
    } on Exception catch (e) {
      errorMessage.value = '$e';
      isLoadingROM.value = false;
    }
  }

  void startEmulation() {
    if (isRunning.value || !isROMLoaded.value) return;

    isRunning.value = true;
    _frameCount = 0;
    _skipFrames = 0;
    _lastFPSUpdate = DateTime.now();
    _frameStopwatch.start();
    _lastFrameTime = DateTime.now();

    if (audioEnabled.value) {
      _audioPlayer.resume();
    }
  }

  void pauseEmulation() {
    isRunning.value = false;
    _frameStopwatch.stop();
    _audioPlayer.pause();
  }

  void resetEmulation() {
    bus.reset();

    clearRewindBuffer();
    startEmulation();
  }

  void stepEmulation() {
    if (isRunning.value || !isROMLoaded.value) return;

    do {
      bus.clock();
    } while (!bus.cpu.complete());

    unawaited(updatePixelBuffer());
  }

  void updateEmulation() {
    if (!isRunning.value) return;

    if (isRewinding.value) {
      unawaited(_handleRewind());

      return;
    }

    bus.ppu.renderMode = renderMode.value;

    final now = DateTime.now();
    final elapsedMicroseconds = now.difference(_lastFrameTime).inMicroseconds;
    final elapsedMs = elapsedMicroseconds / 1000.0;

    final shouldUpdateFrame =
        uncapFramerate.value || elapsedMs >= _targetFrameTimeMs;

    if (!shouldUpdateFrame) {
      final isAudioReady = isROMLoaded.value &&
          bus.cart != null &&
          audioEnabled.value &&
          bus.hasAudioData();

      if (isAudioReady) {
        final audioBuffer = bus.getAudioBuffer();

        unawaited(_audioPlayer.addSamples(audioBuffer));
      }

      return;
    }

    _lastFrameTime = now;

    try {
      if (isROMLoaded.value && bus.cart != null) {
        do {
          bus.clock();
        } while (!bus.ppu.frameComplete);

        bus.ppu.frameComplete = false;

        _statesSavedSinceLastFrame++;

        if (_statesSavedSinceLastFrame >= _saveStateEveryNFrames) {
          if (rewindEnabled.value) {
            unawaited(_saveRewindState());
          }

          _statesSavedSinceLastFrame = 0;
        }

        if (currentFPS.value < 58.0 && _skipFrames < _maxFrameSkip) {
          _skipFrames++;
        } else if (currentFPS.value > 62.0 && _skipFrames > 0) {
          _skipFrames--;
        }

        final shouldRender = _frameCount % (_skipFrames + 1) == 0;
        if (shouldRender) {
          unawaited(updatePixelBuffer());
        }

        if (audioEnabled.value && bus.hasAudioData()) {
          final audioBuffer = bus.getAudioBuffer();
          unawaited(_audioPlayer.addSamples(audioBuffer));
        }

        _frameCount++;
        final now = DateTime.now();

        if (now.difference(_lastFPSUpdate).inMilliseconds >= 1000) {
          final fps = _frameCount /
              (now.difference(_lastFPSUpdate).inMilliseconds / 1000.0);
          currentFPS.value = fps;
          _frameCount = 0;
          _lastFPSUpdate = now;
        }
      } else {
        unawaited(updatePixelBuffer());
      }
    } on Exception catch (e) {
      developer.log('$e');
      pauseEmulation();
      errorMessage.value = '$e';
    }
  }

  Future<void> _handleRewind() async {
    await Future.microtask(() {
      final state = _rewindBuffer.popState();

      if (state != null) {
        bus.restoreState(state);
        _updateRewindProgress();
        unawaited(updatePixelBuffer());
      } else {
        stopRewind();
      }
    });
  }

  void _updateRewindProgress() {
    if (_rewindBuffer.maxFrames > 0) {
      rewindProgress.value = _rewindBuffer.length / _rewindBuffer.maxFrames;
    } else {
      rewindProgress.value = 0.0;
    }
  }

  Future<void> _saveRewindState() async {
    // Use scheduleMicrotask to yield control back to event loop
    await Future.microtask(() {
      final state = bus.saveState();
      _rewindBuffer.pushState(state);
      _updateRewindProgress();
    });
  }

  void startRewind() {
    final canRewind =
        isROMLoaded.value && _rewindBuffer.canRewind && rewindEnabled.value;

    if (!canRewind) return;

    isRewinding.value = true;
    _audioPlayer.pause();
  }

  void stopRewind() {
    isRewinding.value = false;

    bus.controller[0] = 0;
    bus.controller[1] = 0;

    if (audioEnabled.value && isRunning.value) _audioPlayer.resume();
  }

  Future<void> rewindFrames(int frames) async {
    if (!isROMLoaded.value) return;

    await Future.microtask(() {
      final state = _rewindBuffer.rewindFrames(frames);

      if (state != null) {
        bus.restoreState(state);
        _updateRewindProgress();
        unawaited(updatePixelBuffer());
      }
    });
  }

  void clearRewindBuffer() {
    _rewindBuffer.clear();

    rewindProgress.value = 0.0;
  }

  bool get canRewind => _rewindBuffer.canRewind;

  double get rewindBufferSeconds => _rewindBuffer.availableRewindSeconds;

  String _getSaveStateKey() {
    final name = romName.value ?? 'unknown';
    return 'save_state_$name';
  }

  Future<void> _checkSaveStateExists() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSaveStateKey();
    hasSaveState.value = prefs.containsKey(key);
  }

  Future<bool> saveState() async {
    if (!isROMLoaded.value) return false;

    try {
      final state = bus.saveState();
      final jsonString = jsonEncode(state.toJson());

      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveStateKey();
      await prefs.setString(key, jsonString);

      hasSaveState.value = true;
      developer.log('Save state saved for ${romName.value}');
      return true;
    } on Exception catch (e) {
      developer.log('Failed to save state: $e');
      errorMessage.value = 'Failed to save state: $e';
      return false;
    }
  }

  Future<bool> loadState() async {
    if (!isROMLoaded.value) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSaveStateKey();
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        errorMessage.value = 'No save state found';
        return false;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = EmulatorStateSerialization.fromJson(json);

      bus.restoreState(state);

      bus.controller[0] = 0;
      bus.controller[1] = 0;

      bus.getAudioBuffer();

      clearRewindBuffer();
      unawaited(updatePixelBuffer());

      developer.log('Save state loaded for ${romName.value}');
      return true;
    } on Exception catch (e) {
      developer.log('Failed to load state: $e');
      errorMessage.value = 'Failed to load state: $e';
      return false;
    }
  }

  void handleKeyDown(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        bus.controller.first |= 0x08;
      case LogicalKeyboardKey.arrowDown:
        bus.controller.first |= 0x04;
      case LogicalKeyboardKey.arrowLeft:
        bus.controller.first |= 0x02;
      case LogicalKeyboardKey.arrowRight:
        bus.controller.first |= 0x01;
      case LogicalKeyboardKey.keyZ:
        bus.controller.first |= 0x80;
      case LogicalKeyboardKey.keyX:
        bus.controller.first |= 0x40;
      case LogicalKeyboardKey.space:
        bus.controller.first |= 0x10;
      case LogicalKeyboardKey.enter:
        bus.controller.first |= 0x20;
      case LogicalKeyboardKey.keyR:
        if (canRewind && rewindEnabled.value) startRewind();

      default:
        break;
    }
  }

  void handleKeyUp(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
        bus.controller.first &= ~0x08;
      case LogicalKeyboardKey.arrowDown:
        bus.controller.first &= ~0x04;
      case LogicalKeyboardKey.arrowLeft:
        bus.controller.first &= ~0x02;
      case LogicalKeyboardKey.arrowRight:
        bus.controller.first &= ~0x01;
      case LogicalKeyboardKey.keyZ:
        bus.controller.first &= ~0x80;
      case LogicalKeyboardKey.keyX:
        bus.controller.first &= ~0x40;
      case LogicalKeyboardKey.space:
        bus.controller.first &= ~0x10;
      case LogicalKeyboardKey.enter:
        bus.controller.first &= ~0x20;
      case LogicalKeyboardKey.keyR:
        if (isRewinding.value) stopRewind();

      default:
        break;
    }
  }

  void changeFilterQuality(FilterQuality quality) =>
      filterQuality.value = quality;

  void toggleUncapFramerate() => uncapFramerate.value = !uncapFramerate.value;

  void toggleDebugger() => isDebuggerVisible.value = !isDebuggerVisible.value;

  void toggleOnScreenController() =>
      isOnScreenControllerVisible.value = !isOnScreenControllerVisible.value;

  void toggleAudio() {
    audioEnabled.value = !audioEnabled.value;

    (audioEnabled.value && isRunning.value)
        ? _audioPlayer.resume()
        : _audioPlayer.pause();
  }

  void toggleRewind() {
    rewindEnabled.value = !rewindEnabled.value;

    if (!rewindEnabled.value) clearRewindBuffer();
  }

  void setRenderMode(RenderMode mode) => renderMode.value = mode;

  void pressButton(String buttonName) {
    switch (buttonName) {
      case 'up':
        bus.controller.first |= 0x08;
      case 'down':
        bus.controller.first |= 0x04;
      case 'left':
        bus.controller.first |= 0x02;
      case 'right':
        bus.controller.first |= 0x01;
      case 'a':
        bus.controller.first |= 0x80;
      case 'b':
        bus.controller.first |= 0x40;
      case 'start':
        bus.controller.first |= 0x10;
      case 'select':
        bus.controller.first |= 0x20;
      default:
        break;
    }
  }

  void releaseButton(String buttonName) {
    switch (buttonName) {
      case 'up':
        bus.controller.first &= ~0x08;
      case 'down':
        bus.controller.first &= ~0x04;
      case 'left':
        bus.controller.first &= ~0x02;
      case 'right':
        bus.controller.first &= ~0x01;
      case 'a':
        bus.controller.first &= ~0x80;
      case 'b':
        bus.controller.first &= ~0x40;
      case 'start':
        bus.controller.first &= ~0x10;
      case 'select':
        bus.controller.first &= ~0x20;
      default:
        break;
    }
  }

  Future<void> dispose() async {
    screenImage.value?.dispose();
    await _imageStreamController.close();
    await _audioPlayer.dispose();
  }
}
