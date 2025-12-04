import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:fnes/components/audio_manager.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cartridge.dart';
import 'package:fnes/components/emulator_state.dart';
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
  final RewindBuffer _rewindBuffer = RewindBuffer();
  int _statesSavedSinceLastFrame = 0;
  static const int _saveStateEveryNFrames = 1;

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
    var bufferIndex = 0;
    final pixelBuffer = Uint8List(256 * 240 * 4);

    for (var y = 0; y < 240; y++) {
      final row = bus.ppu.screenPixels[y];
      for (var x = 0; x < 256; x++) {
        int colorIndex;

        if (isROMLoaded.value && bus.cart != null) {
          colorIndex = row[x] % bus.ppu.palScreen.length;
        } else {
          colorIndex = 0;
        }

        final color = bus.ppu.palScreen[colorIndex];
        pixelBuffer[bufferIndex++] = (color.r * 255).round();
        pixelBuffer[bufferIndex++] = (color.g * 255).round();
        pixelBuffer[bufferIndex++] = (color.b * 255).round();
        pixelBuffer[bufferIndex++] = 255;
      }
    }

    final image = await _createScreenImage(pixelBuffer);
    screenImage.value = image;

    frameUpdateTrigger.value = (frameUpdateTrigger.value + 1) % 1000000;

    if (!_imageStreamController.isClosed) {
      _imageStreamController.add(image);
    }
  }

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
      _handleRewind();

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

        _audioPlayer.addSamples(audioBuffer);
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
          _rewindBuffer.pushState(bus.saveState());
          _statesSavedSinceLastFrame = 0;
          _updateRewindProgress();
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
          _audioPlayer.addSamples(audioBuffer);
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

  void _handleRewind() {
    final state = _rewindBuffer.popState();

    if (state != null) {
      bus.restoreState(state);
      _updateRewindProgress();
      unawaited(updatePixelBuffer());
    } else {
      stopRewind();
    }
  }

  void _updateRewindProgress() {
    if (_rewindBuffer.maxFrames > 0) {
      rewindProgress.value = _rewindBuffer.length / _rewindBuffer.maxFrames;
    } else {
      rewindProgress.value = 0.0;
    }
  }

  void startRewind() {
    if (!isROMLoaded.value || !_rewindBuffer.canRewind) return;

    isRewinding.value = true;
    _audioPlayer.pause();
  }

  void stopRewind() {
    isRewinding.value = false;

    bus.controller[0] = 0;
    bus.controller[1] = 0;

    if (audioEnabled.value && isRunning.value) _audioPlayer.resume();
  }

  void rewindFrames(int frames) {
    if (!isROMLoaded.value) return;

    final state = _rewindBuffer.rewindFrames(frames);

    if (state != null) {
      bus.restoreState(state);
      _updateRewindProgress();
      unawaited(updatePixelBuffer());
    }
  }

  void clearRewindBuffer() {
    _rewindBuffer.clear();
    rewindProgress.value = 0.0;
  }

  bool get canRewind => _rewindBuffer.canRewind;

  double get rewindBufferSeconds => _rewindBuffer.availableRewindSeconds;

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
        if (canRewind) startRewind();

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
