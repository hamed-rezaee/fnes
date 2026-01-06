import 'package:flutter/material.dart';
import 'package:fnes/components/apu.dart';
import 'package:fnes/controllers/audio_debug_view_controller.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:fnes/widgets/custom_segmented_button.dart';
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
  late final Signal<double> volume;

  @override
  void initState() {
    super.initState();

    controller = AudioDebugViewController(
      apu: widget.apu,
      nesEmulatorController: widget.nesEmulatorController,
    );

    volume = signal(widget.nesEmulatorController.audioPlayer.volume);
  }

  @override
  Widget build(BuildContext context) => Watch((_) {
    final (samples, peak, rms) = (
      controller.waveformSamples.value,
      controller.peakAmplitude.value,
      controller.rmsLevel.value,
    );

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChannelSelector(),
        _buildVolumeSlider(),
        Container(
          width: 380,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade100,
          ),
          child: CustomPaint(painter: WaveformPainter(samples: samples)),
        ),
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
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: _formatLevel(peak)),
              const TextSpan(
                text: ' | RMS: ',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: _formatLevel(rms)),
            ],
          ),
        ),
      ],
    );
  });

  Widget _buildChannelSelector() => Watch(
    (_) => SizedBox(
      width: 380,
      child: CustomSegmentedButton<AudioChannel>(
        showSelectedIcon: false,
        multiSelectionEnabled: true,
        isEmptySelectionAllowed: true,
        toLabel: (channel) => channel.label,
        items: AudioChannel.values,
        selectedItems: {
          if (controller.pulse1Enabled.value) AudioChannel.pulse1,
          if (controller.pulse2Enabled.value) AudioChannel.pulse2,
          if (controller.triangleEnabled.value) AudioChannel.triangle,
          if (controller.noiseEnabled.value) AudioChannel.noise,
          if (controller.dmcEnabled.value) AudioChannel.dmc,
        },
        onSelectedPatternTableChanged: (selected) {
          controller.pulse1Enabled.value = selected.contains(
            AudioChannel.pulse1,
          );
          controller.pulse2Enabled.value = selected.contains(
            AudioChannel.pulse2,
          );
          controller.triangleEnabled.value = selected.contains(
            AudioChannel.triangle,
          );
          controller.noiseEnabled.value = selected.contains(AudioChannel.noise);
          controller.dmcEnabled.value = selected.contains(AudioChannel.dmc);
          widget.apu.pulse1.enable = controller.pulse1Enabled.value;
          widget.apu.pulse2.enable = controller.pulse2Enabled.value;
          widget.apu.triangle.enable = controller.triangleEnabled.value;
          widget.apu.noise.enable = controller.noiseEnabled.value;

          if (controller.dmcEnabled.value) {
            if (widget.apu.dmc.duration == 0) {
              widget.apu.dmc.duration = widget.apu.dmc.sampleLength;
              widget.apu.dmc.currentAddress = widget.apu.dmc.sampleAddress;
            }
          } else {
            widget.apu.dmc.duration = 0;
          }
        },
      ),
    ),
  );

  Widget _buildVolumeSlider() => Watch((_) {
    final audioManager = widget.nesEmulatorController.audioPlayer;

    return SizedBox(
      width: 370,
      child: Row(
        children: [
          const Text(
            'Volume',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Slider(
              value: volume.value,
              divisions: 20,
              onChanged: (value) {
                volume.value = value;
                audioManager.setVolume(value);
              },
            ),
          ),
          SizedBox(
            child: Text(
              '${(volume.value * 100).round()}%',
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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
