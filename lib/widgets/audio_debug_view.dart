import 'package:flutter/material.dart';
import 'package:fnes/components/apu.dart';
import 'package:fnes/controllers/audio_debug_view_controller.dart';
import 'package:signals/signals_flutter.dart';

class AudioDebugView extends StatefulWidget {
  const AudioDebugView({required this.apu, super.key});

  final APU apu;

  @override
  State<AudioDebugView> createState() => _AudioDebugViewState();
}

class _AudioDebugViewState extends State<AudioDebugView> {
  late final AudioDebugViewController controller;

  @override
  void initState() {
    super.initState();

    controller = AudioDebugViewController(apu: widget.apu);
  }

  @override
  Widget build(BuildContext context) => Watch((_) {
        final samples = controller.waveformSamples.value;
        final currentAmplitude = controller.currentAmplitude.value;
        final peakAmplitude = controller.peakAmplitude.value;
        final rmsLevel = controller.rmsLevel.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 320,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child: CustomPaint(painter: WaveformPainter(samples: samples)),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                  fontFamily: 'MonospaceFont',
                ),
                children: [
                  const TextSpan(
                    text: 'Current Level: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: _formatLevel(currentAmplitude)),
                  const TextSpan(
                    text: ' | Peak: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: _formatLevel(peakAmplitude)),
                  const TextSpan(
                    text: ' | RMS Level: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: _formatLevel(rmsLevel)),
                ],
              ),
            ),
          ],
        );
      });

  static String _formatLevel(double level) {
    final percentage = (level * 100).toStringAsFixed(1);

    return '$percentage%';
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }
}

class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.samples});

  final List<double> samples;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final scaleX = size.width / samples.length;
    final scaleY = size.height / 2.5;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 0.75,
    );

    final path = Path()..moveTo(0, centerY - (samples[0] * scaleY));

    for (var i = 1; i < samples.length; i++) {
      final x = i * scaleX;
      final y = centerY - (samples[i] * scaleY);

      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    final thresholdPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    canvas
      ..drawLine(
        Offset(0, centerY - scaleY),
        Offset(size.width, centerY - scaleY),
        thresholdPaint,
      )
      ..drawLine(
        Offset(0, centerY + scaleY),
        Offset(size.width, centerY + scaleY),
        thresholdPaint,
      );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.samples != samples;
}
