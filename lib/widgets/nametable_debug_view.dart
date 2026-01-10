import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:fnes/components/bus.dart';
import 'package:fnes/components/color_palette.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';

class NametableDebugView extends StatefulWidget {
  const NametableDebugView({
    required this.bus,
    required this.nesEmulatorController,
    super.key,
  });

  final Bus bus;
  final NESEmulatorController nesEmulatorController;

  @override
  State<NametableDebugView> createState() => _NametableDebugViewState();
}

class _NametableDebugViewState extends State<NametableDebugView> {
  ui.Image? _nametableImage;
  StreamSubscription<dynamic>? _frameSubscription;
  final int _width = 512;
  final int _height = 480;
  bool _isGenerating = false;
  int _frameCount = 0;

  double _scrollX = 0;
  double _scrollY = 0;

  @override
  void initState() {
    super.initState();

    _frameSubscription = widget.nesEmulatorController.imageStream.listen((_) {
      if (mounted) {
        _updateScrollPosition();
        setState(() {});

        _frameCount++;

        if (_frameCount % 4 == 0) unawaited(_generateImage());
      }
    });
  }

  void _updateScrollPosition() {
    final ppu = widget.bus.ppu;

    _scrollX = ppu.frameScrollX.toDouble();
    _scrollY = ppu.frameScrollY.toDouble();
  }

  Future<void> _generateImage() async {
    if (_isGenerating) return;
    _isGenerating = true;

    try {
      final ppu = widget.bus.ppu;
      final pixels = Uint8List(_width * _height * 4);
      final pixelsData = ByteData.view(pixels.buffer);

      for (var nt = 0; nt < 4; nt++) {
        final baseX = (nt & 1) * 256;
        final baseY = (nt ~/ 2) * 240;
        final baseAddr = 0x2000 + (nt * 0x400);

        for (var y = 0; y < 30; y++) {
          for (var x = 0; x < 32; x++) {
            final tileAddr = baseAddr + (y * 32) + x;
            final attrAddr = baseAddr + 0x3C0 + ((y ~/ 4) * 8) + (x ~/ 4);

            final tileId = ppu.ppuRead(tileAddr);
            final attrByte = ppu.ppuRead(attrAddr);

            var paletteGroup = 0;
            if ((y % 4) >= 2) paletteGroup |= 2;
            if ((x % 4) >= 2) paletteGroup |= 1;

            final paletteIndex = (attrByte >> (paletteGroup * 2)) & 0x03;

            final bgPatternTable = ppu.control.patternBackground == 1
                ? 0x1000
                : 0x0000;
            final tilePatternAddr = bgPatternTable + (tileId * 16);

            for (var row = 0; row < 8; row++) {
              final patternLow = ppu.ppuRead(tilePatternAddr + row);
              final patternHigh = ppu.ppuRead(tilePatternAddr + row + 8);

              for (var col = 0; col < 8; col++) {
                final bitMask = 1 << (7 - col);
                final pLow = (patternLow & bitMask) != 0 ? 1 : 0;
                final pHigh = (patternHigh & bitMask) != 0 ? 1 : 0;
                final pixelVal = (pHigh << 1) | pLow;

                int colorAddr;
                if (pixelVal == 0) {
                  colorAddr = 0x3F00;
                } else {
                  colorAddr = 0x3F00 + (paletteIndex << 2) + pixelVal;
                }

                final paletteEntry = ppu.ppuRead(colorAddr) & 0x3F;
                final color = colorPalette[paletteEntry];

                final px = baseX + (x * 8) + col;
                final py = baseY + (y * 8) + row;
                final bufferIndex = (py * _width + px) * 4;

                final r = (color >> 16) & 0xFF;
                final g = (color >> 8) & 0xFF;
                final b = color & 0xFF;

                pixelsData
                  ..setUint8(bufferIndex + 0, r)
                  ..setUint8(bufferIndex + 1, g)
                  ..setUint8(bufferIndex + 2, b)
                  ..setUint8(bufferIndex + 3, 255);
              }
            }
          }
        }
      }

      final image = await _createImageFromPixels(pixels, _width, _height);

      if (mounted) {
        setState(() {
          _nametableImage?.dispose();
          _nametableImage = image;
        });
      } else {
        image.dispose();
      }
    } on Exception catch (e) {
      debugPrint('Error generating nametable image: $e');
    } finally {
      _isGenerating = false;
    }
  }

  Future<ui.Image> _createImageFromPixels(
    Uint8List pixels,
    int width,
    int height,
  ) {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AspectRatio(
        aspectRatio: _width / _height,
        child: ClipRect(
          child: CustomPaint(
            painter: _NametablePainter(
              image: _nametableImage,
              scrollX: _scrollX,
              scrollY: _scrollY,
            ),
          ),
        ),
      ),
    ],
  );

  @override
  void dispose() {
    unawaited(_frameSubscription?.cancel());
    _nametableImage?.dispose();

    super.dispose();
  }
}

class _NametablePainter extends CustomPainter {
  _NametablePainter({
    required this.image,
    required this.scrollX,
    required this.scrollY,
  });

  final ui.Image? image;
  final double scrollX;
  final double scrollY;

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        image: image!,
        filterQuality: FilterQuality.none,
      );
    }

    final scaleX = size.width / 512.0;
    final scaleY = size.height / 480.0;

    final strokePaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = const Color(0xFFFF0000).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    _drawWrappedRect(
      canvas,
      scrollX * scaleX,
      scrollY * scaleY,
      256 * scaleX,
      240 * scaleY,
      size.width,
      size.height,
      fillPaint,
    );

    _drawWrappedRect(
      canvas,
      scrollX * scaleX,
      scrollY * scaleY,
      256 * scaleX,
      240 * scaleY,
      size.width,
      size.height,
      strokePaint,
    );
  }

  void _drawWrappedRect(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    double totalW,
    double totalH,
    Paint paint,
  ) {
    canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);

    if (x + w > totalW) {
      canvas.drawRect(Rect.fromLTWH(x - totalW, y, w, h), paint);
    }

    if (y + h > totalH) {
      canvas.drawRect(Rect.fromLTWH(x, y - totalH, w, h), paint);
    }

    if (x + w > totalW && y + h > totalH) {
      canvas.drawRect(Rect.fromLTWH(x - totalW, y - totalH, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NametablePainter oldDelegate) => true;
}
