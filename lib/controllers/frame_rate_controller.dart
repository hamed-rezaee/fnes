import 'package:signals/signals_flutter.dart';

class FrameRateController {
  static const int maxFrameSkip = 0;
  static const double targetFrameTimeMs = 1000 / 60;

  int frameCount = 0;
  int skipFrames = 0;
  DateTime lastFPSUpdate = DateTime.now();
  DateTime lastFrameTime = DateTime.now();

  final Signal<double> currentFPS = signal(0);

  void initialize() {
    frameCount = 0;
    skipFrames = 0;
    lastFPSUpdate = DateTime.now();
    lastFrameTime = DateTime.now();
  }

  bool shouldUpdateFrame({required bool uncapFramerate}) {
    final now = DateTime.now();
    final elapsedMicroseconds = now.difference(lastFrameTime).inMicroseconds;
    final elapsedMs = elapsedMicroseconds / 1000;

    return uncapFramerate || elapsedMs >= targetFrameTimeMs;
  }

  void markFrameTime() => lastFrameTime = DateTime.now();

  void updateFPSCounter(double currentFps) {
    frameCount++;
    final now = DateTime.now();

    if (now.difference(lastFPSUpdate).inMilliseconds >= 1000) {
      final fps =
          frameCount / (now.difference(lastFPSUpdate).inMilliseconds / 1000);
      currentFPS.value = fps;
      frameCount = 0;
      lastFPSUpdate = now;

      if (fps < 58 && skipFrames < maxFrameSkip) {
        skipFrames++;
      } else if (fps > 62 && skipFrames > 0) {
        skipFrames--;
      }
    }
  }

  bool shouldRenderFrame() => frameCount % (skipFrames + 1) == 0;

  double getFPS() => currentFPS.value;
}
