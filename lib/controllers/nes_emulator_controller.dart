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
import 'package:fnes/components/color_palette.dart';
import 'package:fnes/components/emulator_state.dart';
import 'package:fnes/controllers/audio_state_manager.dart';
import 'package:fnes/controllers/frame_rate_controller.dart';
import 'package:fnes/controllers/input_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals_flutter.dart';

enum RenderMode {
  both('All'),
  background('Background'),
  sprites('Sprites');

  const RenderMode(this.label);

  final String label;
}

class NESEmulatorController {
  NESEmulatorController({required this.bus}) {
    bus.setSampleFrequency(44100);
    _audioStateManager = AudioStateManager(_audioPlayer);
    unawaited(_initializeAudio());
  }

  final Bus bus;
  final StreamController<Image> _imageStreamController =
      StreamController<Image>.broadcast();

  static const int _saveStateEveryNFrames = 1;

  final Signal<bool> isRunning = signal(false);
  final Signal<bool> isROMLoaded = signal(false);
  final Signal<String?> romFileName = signal<String?>(null);
  final Signal<Image?> screenImage = signal<Image?>(null);
  final Signal<FilterQuality> filterQuality =
      signal<FilterQuality>(FilterQuality.none);
  final Signal<bool> isDebuggerVisible = signal(true);
  final Signal<bool> isOnScreenControllerVisible = signal(false);
  final Signal<bool> uncapFramerate = signal(false);
  final Signal<RenderMode> renderMode = signal(RenderMode.both);

  final Signal<bool> isLoadingROM = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<int> frameUpdateTrigger = signal(0);

  final Signal<bool> rewindEnabled = signal(true);
  final Signal<bool> isRewinding = signal(false);
  final Signal<double> rewindProgress = signal(0);
  final Signal<bool> hasSaveState = signal(false);

  late final Computed<String?> romName = computed(() {
    final fileName = romFileName.value;
    return fileName?.split('.').first;
  });

  late final Computed<double> currentFPS =
      computed(() => _frameRateController.currentFPS.value);

  final RewindBuffer _rewindBuffer = RewindBuffer();
  int _statesSavedSinceLastFrame = 0;
  int _turboFrameCounter = 0;
  int _turboPressedButtons = 0;
  final AudioManager _audioPlayer = AudioManager();
  late final AudioStateManager _audioStateManager;
  final FrameRateController _frameRateController = FrameRateController();
  final Stopwatch _frameStopwatch = Stopwatch();

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
    final colorPalette = _colorPalette;
    final pixels = bus.ppu.screenPixels;

    if (!romLoaded) {
      buffer32.fillRange(0, width * height, colorPalette[0]);
    } else {
      for (var i = 0; i < width * height; i++) {
        buffer32[i] = colorPalette[pixels[i]];
      }
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
    colorPalette.map(
      (colors) {
        final hex = colors;
        final r = (hex >> 16) & 0xFF;
        final g = (hex >> 8) & 0xFF;
        final b = hex & 0xFF;
        return (255 << 24) | (b << 16) | (g << 8) | r;
      },
    ).toList(),
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
    _frameRateController.initialize();
    _frameStopwatch.start();
    _audioStateManager.resumeIfEnabled();
  }

  void pauseEmulation() {
    isRunning.value = false;
    _frameStopwatch.stop();
    _audioStateManager.pause();
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

    if (!_frameRateController.shouldUpdateFrame(
      uncapFramerate: uncapFramerate.value,
    )) {
      _updateAudioIfReady();
      return;
    }

    _frameRateController.markFrameTime();

    try {
      _updateEmulationFrame();
    } on Exception catch (e) {
      _handleEmulationError(e);
    }
  }

  void _updateEmulationFrame() {
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

      _updateTurboButtons();

      _frameRateController
          .updateFPSCounter(_frameRateController.currentFPS.value);

      if (_frameRateController.shouldRenderFrame()) {
        unawaited(updatePixelBuffer());
      }

      _updateAudioIfReady();
    } else {
      unawaited(updatePixelBuffer());
    }
  }

  void _updateAudioIfReady() {
    if (isROMLoaded.value &&
        bus.cart != null &&
        _audioStateManager.isEnabled.value &&
        bus.hasAudioData()) {
      final audioBuffer = bus.getAudioBuffer();
      unawaited(_audioStateManager.addSamples(audioBuffer));
    }
  }

  void _handleEmulationError(Exception e) {
    developer.log('Emulation error: $e');
    pauseEmulation();
    errorMessage.value = '$e';
  }

  Future<void> _handleRewind() async => Future.microtask(() {
        final state = _rewindBuffer.popState();

        if (state != null) {
          bus.controller[0] = 0;
          bus.controller[1] = 0;
          bus.restoreState(state);
          _updateRewindProgress();
          unawaited(updatePixelBuffer());
        } else {
          stopRewind();
        }
      });

  void _updateRewindProgress() {
    if (_rewindBuffer.maxFrames > 0) {
      rewindProgress.value = _rewindBuffer.length / _rewindBuffer.maxFrames;
    } else {
      rewindProgress.value = 0.0;
    }
  }

  Future<void> _saveRewindState() async => Future.microtask(() {
        final state = bus.saveState();
        _rewindBuffer.pushState(state);
        _updateRewindProgress();
      });

  void startRewind() {
    final canRewind =
        isROMLoaded.value && _rewindBuffer.canRewind && rewindEnabled.value;

    if (!canRewind) return;

    isRewinding.value = true;
    _audioPlayer.pause();
  }

  void stopRewind() {
    isRewinding.value = false;

    if (_audioStateManager.isEnabled.value && isRunning.value) {
      _audioStateManager.resumeIfEnabled();
    }
  }

  Future<void> rewindFrames(int frames) async {
    if (!isROMLoaded.value) return;

    await Future.microtask(() {
      final state = _rewindBuffer.rewindFrames(frames);

      if (state != null) {
        bus.controller[0] = 0;
        bus.controller[1] = 0;
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
    if (key == LogicalKeyboardKey.keyR) {
      if (canRewind && rewindEnabled.value) startRewind();
      return;
    }

    final bit = InputMapper.getKeyBit(key);
    if (bit != null) {
      if (bit == InputMapper.turboA || bit == InputMapper.turboB) {
        _turboPressedButtons |= bit;
      } else {
        bus.controller.first =
            InputMapper.pressButton(bus.controller.first, bit);
      }
    }
  }

  void handleKeyUp(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyR) {
      if (isRewinding.value) stopRewind();
      return;
    }

    final bit = InputMapper.getKeyBit(key);
    if (bit != null) {
      if (bit == InputMapper.turboA || bit == InputMapper.turboB) {
        _turboPressedButtons &= ~bit;
      } else {
        bus.controller.first =
            InputMapper.releaseButton(bus.controller.first, bit);
      }
    }
  }

  void _updateTurboButtons() {
    _turboFrameCounter = (_turboFrameCounter + 1) % 6;

    if ((_turboPressedButtons & InputMapper.turboA) != 0) {
      if (_turboFrameCounter < 3) {
        bus.controller.first =
            InputMapper.pressButton(bus.controller.first, InputMapper.buttonA);
      } else {
        bus.controller.first = InputMapper.releaseButton(
          bus.controller.first,
          InputMapper.buttonA,
        );
      }
    } else if ((bus.controller.first & InputMapper.buttonA) != 0) {
      bus.controller.first =
          InputMapper.pressButton(bus.controller.first, InputMapper.buttonA);
    }

    if ((_turboPressedButtons & InputMapper.turboB) != 0) {
      if (_turboFrameCounter < 3) {
        bus.controller.first =
            InputMapper.pressButton(bus.controller.first, InputMapper.buttonB);
      } else {
        bus.controller.first = InputMapper.releaseButton(
          bus.controller.first,
          InputMapper.buttonB,
        );
      }
    } else if ((bus.controller.first & InputMapper.buttonB) != 0) {
      bus.controller.first =
          InputMapper.pressButton(bus.controller.first, InputMapper.buttonB);
    }
  }

  void changeFilterQuality(FilterQuality quality) =>
      filterQuality.value = quality;

  void toggleUncapFramerate() => uncapFramerate.value = !uncapFramerate.value;

  void toggleDebugger() => isDebuggerVisible.value = !isDebuggerVisible.value;

  void toggleOnScreenController() =>
      isOnScreenControllerVisible.value = !isOnScreenControllerVisible.value;

  void toggleAudio() => _audioStateManager.toggle();

  void toggleRewind() {
    rewindEnabled.value = !rewindEnabled.value;

    if (!rewindEnabled.value) clearRewindBuffer();
  }

  void setRenderMode(RenderMode mode) => renderMode.value = mode;

  void pressButton(String buttonName) {
    final bit = InputMapper.getButtonBit(buttonName);

    if (bit != null) {
      bus.controller.first = InputMapper.pressButton(bus.controller.first, bit);
    }
  }

  void releaseButton(String buttonName) {
    final bit = InputMapper.getButtonBit(buttonName);

    if (bit != null) {
      bus.controller.first =
          InputMapper.releaseButton(bus.controller.first, bit);
    }
  }

  Future<void> dispose() async {
    screenImage.value?.dispose();
    await _imageStreamController.close();
    await _audioStateManager.dispose();
  }
}
