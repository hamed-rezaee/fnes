import 'package:signals/signals_flutter.dart';

class FrameRateController {
  static const int maxFrameSkip = 0;
  static const int fpsUpdateIntervalMs = 500;

  double _targetFps = 60;

  void setTargetFps(double fps) => _targetFps = fps;

  int frameCount = 0;
  int skipFrames = 0;
  DateTime lastFPSUpdate = DateTime.now();
  DateTime lastFrameTime = DateTime.now();

  final List<double> _fpsHistory = List.filled(_fpsHistorySize, 0);
  static const int _fpsHistorySize = 10;
  int _fpsHistoryIndex = 0;
  int _fpsHistoryCount = 0;

  final Signal<double> currentFPS = signal(0);

  void initialize() {
    frameCount = 0;
    skipFrames = 0;
    lastFPSUpdate = DateTime.now();
    lastFrameTime = DateTime.now();
    _fpsHistoryIndex = 0;
    _fpsHistoryCount = 0;
  }

  void markFrameTime() => lastFrameTime = DateTime.now();

  void updateFPSCounter(double currentFps) {
    frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(lastFPSUpdate).inMilliseconds;

    if (elapsed >= fpsUpdateIntervalMs) {
      final fps = frameCount / (elapsed / 1000);

      _fpsHistory[_fpsHistoryIndex] = fps;
      _fpsHistoryIndex = (_fpsHistoryIndex + 1) % _fpsHistorySize;

      if (_fpsHistoryCount < _fpsHistorySize) _fpsHistoryCount++;

      var sum = 0.0;

      for (var i = 0; i < _fpsHistoryCount; i++) {
        sum += _fpsHistory[i];
      }

      final avgFps = sum / _fpsHistoryCount;

      currentFPS.value = avgFps;
      frameCount = 0;
      lastFPSUpdate = now;

      if (avgFps < (_targetFps - 2) && skipFrames < maxFrameSkip) {
        skipFrames++;
      } else if (avgFps > (_targetFps + 2) && skipFrames > 0) {
        skipFrames--;
      }
    }
  }

  bool shouldRenderFrame() => frameCount % (skipFrames + 1) == 0;

  double getFPS() => currentFPS.value;
}
