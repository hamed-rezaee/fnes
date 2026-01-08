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

  final List<double> _fpsHistory = [];
  static const int _fpsHistorySize = 10;

  final Signal<double> currentFPS = signal(0);

  void initialize() {
    frameCount = 0;
    skipFrames = 0;
    lastFPSUpdate = DateTime.now();
    lastFrameTime = DateTime.now();
    _fpsHistory.clear();
  }

  void markFrameTime() => lastFrameTime = DateTime.now();

  void updateFPSCounter(double currentFps) {
    frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(lastFPSUpdate).inMilliseconds;

    if (elapsed >= fpsUpdateIntervalMs) {
      final fps = frameCount / (elapsed / 1000);

      _fpsHistory.add(fps);

      if (_fpsHistory.length > _fpsHistorySize) _fpsHistory.removeAt(0);

      final avgFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
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
