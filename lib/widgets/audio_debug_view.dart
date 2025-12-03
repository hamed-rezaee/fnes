import 'package:flutter/material.dart';
import 'package:fnes/components/apu.dart';
import 'package:fnes/controllers/audio_debug_view_controller.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:signals/signals_flutter.dart';

class AudioDebugView extends StatefulWidget {
  const AudioDebugView({
    required this.apu,
    required this.nesEmulatorController,
    super.key,
  });

  final NESEmulatorController nesEmulatorController;
  final APU apu;

  @override
  State<AudioDebugView> createState() => _AudioDebugViewState();
}

class _AudioDebugViewState extends State<AudioDebugView> {
  late final AudioDebugViewController controller;

  @override
  void initState() {
    super.initState();

    controller = AudioDebugViewController(
      apu: widget.apu,
      nesEmulatorController: widget.nesEmulatorController,
    );
  }

  @override
  Widget build(BuildContext context) => Watch((_) {
        final (samples, peak, rms) = (
          controller.waveformSamples.value,
          controller.peakAmplitude.value,
          controller.rmsLevel.value,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChannelSelector(),
            const SizedBox(height: 10),
            Container(
              width: 320,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child: CustomPaint(
                painter: WaveformPainter(
                  samples: samples,
                ),
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.black,
                  fontFamily: 'MonospaceFont',
                ),
                children: [
                  const TextSpan(
                    text: 'Peak: ',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: _formatLevel(peak)),
                  const TextSpan(
                    text: ' | RMS: ',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: _formatLevel(rms)),
                ],
              ),
            ),
          ],
        );
      });

  Widget _buildChannelSelector() => Watch(
        (_) => SegmentedButton<AudioChannel>(
          showSelectedIcon: false,
          multiSelectionEnabled: true,
          emptySelectionAllowed: true,
          style: ButtonStyle(
            shape: WidgetStateProperty.all(const RoundedRectangleBorder()),
            textStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 8,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontFamily: 'MonospaceFont',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.grey.shade300;
              }

              return null;
            }),
          ),
          segments: [
            for (final channel in AudioChannel.values)
              ButtonSegment(value: channel, label: Text(channel.label)),
          ],
          selected: {
            if (controller.pulse1Enabled.value) AudioChannel.pulse1,
            if (controller.pulse2Enabled.value) AudioChannel.pulse2,
            if (controller.triangleEnabled.value) AudioChannel.triangle,
            if (controller.noiseEnabled.value) AudioChannel.noise,
            if (controller.dmcEnabled.value) AudioChannel.dmc,
          },
          onSelectionChanged: (Set<AudioChannel> selected) {
            controller.pulse1Enabled.value =
                selected.contains(AudioChannel.pulse1);
            controller.pulse2Enabled.value =
                selected.contains(AudioChannel.pulse2);
            controller.triangleEnabled.value =
                selected.contains(AudioChannel.triangle);
            controller.noiseEnabled.value =
                selected.contains(AudioChannel.noise);
            controller.dmcEnabled.value = selected.contains(AudioChannel.dmc);
            widget.apu.pulse1.enable = controller.pulse1Enabled.value;
            widget.apu.pulse2.enable = controller.pulse2Enabled.value;
            widget.apu.triangle.enable = controller.triangleEnabled.value;
            widget.apu.noise.enable = controller.noiseEnabled.value;
            widget.apu.dmc.enable = controller.dmcEnabled.value;
          },
        ),
      );

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
  WaveformPainter({required this.samples, this.color = Colors.black});

  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
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
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.color != color;
}
