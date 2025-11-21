import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnes/components/audio_manager.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/cartridge.dart';
import 'package:fnes/cubits/nes_emulator_state.dart';

class NESEmulatorCubit extends Cubit<NESEmulatorState> {
  NESEmulatorCubit({required this.bus}) : super(const NESEmulatorInitial()) {
    bus.setSampleFrequency(44100);

    unawaited(_initializeAudio());
  }

  final Bus bus;
  final StreamController<Image> _imageStreamController =
      StreamController<Image>.broadcast();

  static const int _maxFrameSkip = 0;
  static const double _targetFrameTime = 1000.0 / 60.0;

  bool _isRunning = false;
  bool _isROMLoaded = false;
  String? _romFileName;
  Image? _screenImage;
  FilterQuality _filterQuality = FilterQuality.none;
  bool _isDebuggerVisible = true;

  int _frameCount = 0;
  int _skipFrames = 0;
  double _currentFPS = 0;
  DateTime _lastFPSUpdate = DateTime.now();

  final Stopwatch _frameStopwatch = Stopwatch();

  final AudioManager _audioPlayer = AudioManager();
  bool _audioEnabled = true;

  Stream<Image> get imageStream => _imageStreamController.stream;

  bool get isRunning => _isRunning;

  bool get isROMLoaded => _isROMLoaded;

  String? get romFileName => _romFileName;

  String? get romName => _romFileName?.split('.').first;

  Image? get screenImage => _screenImage;

  double get currentFPS => _currentFPS;

  FilterQuality get filterQuality => _filterQuality;

  bool get showDebugger => _isDebuggerVisible;

  bool get audioEnabled => _audioEnabled;

  Future<void> _initializeAudio() async {
    await _audioPlayer.initialize();
  }

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

        if (_isROMLoaded && bus.cart != null) {
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
    _screenImage = image;

    if (!_imageStreamController.isClosed) {
      _imageStreamController.add(image);
    }
  }

  Future<void> loadROMFile() async {
    try {
      emit(const NESEmulatorLoadingROM());

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

            _isROMLoaded = true;
            _romFileName = file.name;
            emit(NESEmulatorROMLoaded(fileName: file.name));
            startEmulation();
          } else {
            emit(const NESEmulatorError(message: 'Invalid ROM file format'));
          }
        }
      } else {
        emit(const NESEmulatorInitial());
      }
    } on Exception catch (e) {
      emit(NESEmulatorError(message: '$e'));
    }
  }

  void startEmulation() {
    if (_isRunning || !_isROMLoaded) return;

    _isRunning = true;
    _frameCount = 0;
    _skipFrames = 0;
    _lastFPSUpdate = DateTime.now();
    _frameStopwatch.start();

    if (_audioEnabled) {
      _audioPlayer.resume();
    }

    emit(NESEmulatorRunning(currentFPS: _currentFPS, frameCount: _frameCount));
  }

  void pauseEmulation() {
    _isRunning = false;
    _frameStopwatch.stop();
    _audioPlayer.pause();

    emit(const NESEmulatorPaused());
  }

  void resetEmulation() {
    bus.reset();
    _audioPlayer.clear();

    startEmulation();
  }

  void stepEmulation() {
    if (_isRunning || !_isROMLoaded) return;

    do {
      bus.clock();
    } while (!bus.cpu.complete());

    unawaited(updatePixelBuffer());

    emit(NESEmulatorRunning(currentFPS: _currentFPS, frameCount: _frameCount));
    emit(const NESEmulatorStepped());
  }

  void updateEmulation() {
    if (!_isRunning) return;

    final elapsed = _frameStopwatch.elapsedMicroseconds / 1000.0;
    if (elapsed < _targetFrameTime) {
      return;
    }
    _frameStopwatch.reset();

    try {
      if (_isROMLoaded && bus.cart != null) {
        do {
          bus.clock();
        } while (!bus.ppu.frameComplete);

        bus.ppu.frameComplete = false;

        if (_currentFPS < 58.0 && _skipFrames < _maxFrameSkip) {
          _skipFrames++;
        } else if (_currentFPS > 62.0 && _skipFrames > 0) {
          _skipFrames--;
        }

        final shouldRender = _frameCount % (_skipFrames + 1) == 0;
        if (shouldRender) {
          unawaited(updatePixelBuffer());
        }

        if (_audioEnabled && bus.hasAudioData()) {
          final audioBuffer = bus.getAudioBuffer();
          _audioPlayer.addSamples(audioBuffer);
        }

        _frameCount++;
        final now = DateTime.now();

        if (now.difference(_lastFPSUpdate).inMilliseconds >= 1000) {
          _currentFPS = _frameCount /
              (now.difference(_lastFPSUpdate).inMilliseconds / 1000.0);
          _frameCount = 0;
          _lastFPSUpdate = now;
        }

        if (shouldRender) {
          emit(
            NESEmulatorFrameUpdated(
              currentFPS: _currentFPS,
              frameCount: _frameCount,
            ),
          );
        }
      } else {
        unawaited(updatePixelBuffer());
      }
    } on Exception catch (e) {
      developer.log('$e');
      pauseEmulation();
      emit(NESEmulatorError(message: '$e'));
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
    }
  }

  void changeFilterQuality(FilterQuality filterQuality) {
    _filterQuality = filterQuality;
    emit(NESEmulatorFilterQualityChanged(filterQuality: filterQuality));
  }

  void toggleDebugger() {
    _isDebuggerVisible = !_isDebuggerVisible;

    emit(NESEmulatorDebuggerToggled(isDebuggerVisible: _isDebuggerVisible));
  }

  void toggleAudio() {
    _audioEnabled = !_audioEnabled;

    if (_audioEnabled && _isRunning) {
      _audioPlayer.resume();
    } else {
      _audioPlayer.pause();
    }
  }

  @override
  Future<void> close() {
    _screenImage?.dispose();
    unawaited(_imageStreamController.close());
    unawaited(_audioPlayer.dispose());

    return super.close();
  }
}
