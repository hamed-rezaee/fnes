import 'dart:typed_data';

import 'package:fnes/components/color_palette.dart';

class ZapperSnapshot {
  const ZapperSnapshot({
    required this.enabled,
    required this.triggerPressed,
    required this.pointerX,
    required this.pointerY,
    required this.pointerOnScreen,
  });

  final bool enabled;
  final bool triggerPressed;
  final double pointerX;
  final double pointerY;
  final bool pointerOnScreen;
}

class Zapper {
  static const int _screenWidth = 256;
  static const int _screenHeight = 240;
  static const double _detectionThreshold = 160;
  static const double _minimumHitRatio = 0.25;
  static const int _sampleRadius = 2;

  bool enabled = false;
  bool triggerPressed = false;
  double pointerX = _screenWidth / 2;
  double pointerY = _screenHeight / 2;
  bool pointerOnScreen = false;

  void reset() {
    triggerPressed = false;
    pointerOnScreen = false;
  }

  void setEnabled({required bool value}) {
    enabled = value;

    if (!enabled) reset();
  }

  void setTrigger({required bool pressed}) =>
      triggerPressed = enabled && pressed;

  void updatePosition(double x, double y, {required bool isWithinScreen}) {
    pointerX = x.clamp(0, _screenWidth - 1).toDouble();
    pointerY = y.clamp(0, _screenHeight - 1).toDouble();
    pointerOnScreen = enabled && isWithinScreen;
  }

  void clearSight() => pointerOnScreen = false;

  ZapperSnapshot snapshot() => ZapperSnapshot(
    enabled: enabled,
    triggerPressed: triggerPressed,
    pointerX: pointerX,
    pointerY: pointerY,
    pointerOnScreen: pointerOnScreen,
  );

  void restoreSnapshot(ZapperSnapshot snapshot) {
    enabled = snapshot.enabled;
    triggerPressed = snapshot.triggerPressed;
    pointerX = snapshot.pointerX;
    pointerY = snapshot.pointerY;
    pointerOnScreen = snapshot.pointerOnScreen && snapshot.enabled;
  }

  void restorePersistentState({
    required bool enabledState,
    required bool triggerState,
    required double x,
    required double y,
    required bool pointerVisible,
  }) {
    enabled = enabledState;
    pointerX = x;
    pointerY = y;
    triggerPressed = enabled && triggerState;
    pointerOnScreen = enabled && pointerVisible;
  }

  bool detectLight(Uint8List screenPixels) {
    if (!enabled || !pointerOnScreen) return false;

    var brightSamples = 0;
    var totalSamples = 0;

    for (var dy = -_sampleRadius; dy <= _sampleRadius; dy++) {
      final sampleY = (pointerY + dy).round().clamp(0, _screenHeight - 1);

      for (var dx = -_sampleRadius; dx <= _sampleRadius; dx++) {
        final sampleX = (pointerX + dx).round().clamp(0, _screenWidth - 1);
        final paletteIndex =
            screenPixels[sampleY * _screenWidth + sampleX] & 0x3F;
        final luminance = _luminanceLut[paletteIndex];

        if (luminance >= _detectionThreshold) brightSamples++;

        totalSamples++;
      }
    }

    final hitRatio = totalSamples == 0 ? 0.0 : brightSamples / totalSamples;

    return hitRatio >= _minimumHitRatio;
  }

  bool previewLightDetection(Uint8List screenPixels) =>
      detectLight(screenPixels);

  static final List<double> _luminanceLut = List<double>.generate(
    colorPalette.length,
    (index) {
      final color = colorPalette[index];
      final r = (color >> 16) & 0xFF;
      final g = (color >> 8) & 0xFF;
      final b = color & 0xFF;

      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    },
  );
}
