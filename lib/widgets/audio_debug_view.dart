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
        final selectedChannel = controller.selectedChannel.value;

        final (samples, peak, rms) = switch (selectedChannel) {
          AudioChannel.pulse1 => (
              controller.pulse1Samples.value,
              controller.pulse1Peak.value,
              controller.pulse1RMS.value,
            ),
          AudioChannel.pulse2 => (
              controller.pulse2Samples.value,
              controller.pulse2Peak.value,
              controller.pulse2RMS.value,
            ),
          AudioChannel.triangle => (
              controller.triangleSamples.value,
              controller.trianglePeak.value,
              controller.triangleRMS.value,
            ),
          AudioChannel.noise => (
              controller.noiseSamples.value,
              controller.noisePeak.value,
              controller.noiseRMS.value,
            ),
          AudioChannel.dmc => (
              controller.dmcSamples.value,
              controller.dmcPeak.value,
              controller.dmcRMS.value,
            ),
          AudioChannel.mixed => (
              controller.waveformSamples.value,
              controller.peakAmplitude.value,
              controller.rmsLevel.value,
            ),
        };

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
                  color: _getChannelColor(selectedChannel),
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

  Widget _buildChannelSelector() => Watch((_) {
        final selectedChannel = controller.selectedChannel.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 4,
                children: [
                  for (final channel in AudioChannel.values)
                    _buildChannelButton(channel, selectedChannel == channel),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChannelToggle(
                    AudioChannel.pulse1,
                    controller.pulse1Enabled,
                  ),
                  _buildChannelToggle(
                    AudioChannel.pulse2,
                    controller.pulse2Enabled,
                  ),
                  _buildChannelToggle(
                    AudioChannel.triangle,
                    controller.triangleEnabled,
                  ),
                  _buildChannelToggle(
                    AudioChannel.noise,
                    controller.noiseEnabled,
                  ),
                  _buildChannelToggle(AudioChannel.dmc, controller.dmcEnabled),
                ],
              ),
            ),
          ],
        );
      });

  Widget _buildChannelButton(AudioChannel channel, bool isSelected) => Material(
        child: InkWell(
          onTap: () => controller.selectedChannel.value = channel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isSelected ? _getChannelColor(channel) : Colors.grey.shade300,
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              channel.label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );

  Widget _buildChannelToggle(
    AudioChannel channel,
    Signal<bool> enabledSignal,
  ) =>
      Watch((_) {
        final isEnabled = enabledSignal.value;

        return GestureDetector(
          onTap: () => controller.toggleChannel(channel),
          child: Row(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: GestureDetector(
                  onTap: () => controller.toggleChannel(channel),
                  child: Icon(
                    isEnabled ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: isEnabled ? Colors.black : Colors.grey,
                  ),
                ),
              ),
              Text(
                channel.label,
                style:
                    const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      });

  Color _getChannelColor(AudioChannel channel) {
    return switch (channel) {
      AudioChannel.pulse1 => Colors.red,
      AudioChannel.pulse2 => Colors.orange,
      AudioChannel.triangle => Colors.blue,
      AudioChannel.noise => Colors.green,
      AudioChannel.dmc => Colors.purple,
      AudioChannel.mixed => Colors.blueGrey,
    };
  }

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
  WaveformPainter({required this.samples, this.color = Colors.blueGrey});

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
