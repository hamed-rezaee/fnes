import 'package:fnes/components/apu.dart';
import 'package:fnes/controllers/nes_emulator_controller.dart';
import 'package:signals/signals_flutter.dart';

enum AudioChannel {
  pulse1('Pulse 1'),
  pulse2('Pulse 2'),
  triangle('Triangle'),
  noise('Noise'),
  dmc('DMC');

  const AudioChannel(this.label);

  final String label;
}

class AudioDebugViewController {
  AudioDebugViewController({
    required this.apu,
    required this.nesEmulatorController,
  }) {
    effect(() {
      nesEmulatorController.frameUpdateTrigger.value;

      updateAudioData();
    });
  }

  final APU apu;
  final NESEmulatorController nesEmulatorController;

  static const int _maxSamples = 256;

  final List<double> _pulse1Buffer = List.generate(_maxSamples, (_) => 0);
  final List<double> _pulse2Buffer = List.generate(_maxSamples, (_) => 0);
  final List<double> _triangleBuffer = List.generate(_maxSamples, (_) => 0);
  final List<double> _noiseBuffer = List.generate(_maxSamples, (_) => 0);
  final List<double> _dmcBuffer = List.generate(_maxSamples, (_) => 0);
  final List<double> _mixedBuffer = List.generate(_maxSamples, (_) => 0);

  final Signal<List<double>> waveformSamples = signal<List<double>>(
    List.generate(_maxSamples, (_) => 0),
  );
  final Signal<double> currentAmplitude = signal(0);
  final Signal<double> peakAmplitude = signal(0);
  final Signal<double> rmsLevel = signal(0);
  final Signal<int> bufferSize = signal(0);

  final Signal<List<double>> pulse1Samples = signal<List<double>>(
    List.generate(_maxSamples, (_) => 0),
  );
  final Signal<double> pulse1Peak = signal(0);
  final Signal<double> pulse1RMS = signal(0);

  final Signal<List<double>> pulse2Samples = signal<List<double>>(
    List.generate(_maxSamples, (_) => 0),
  );
  final Signal<double> pulse2Peak = signal(0);
  final Signal<double> pulse2RMS = signal(0);

  final Signal<List<double>> triangleSamples = signal<List<double>>(
    List.generate(_maxSamples, (_) => 0),
  );
  final Signal<double> trianglePeak = signal(0);
  final Signal<double> triangleRMS = signal(0);

  final Signal<List<double>> noiseSamples = signal<List<double>>(
    List.generate(_maxSamples, (_) => 0),
  );
  final Signal<double> noisePeak = signal(0);
  final Signal<double> noiseRMS = signal(0);

  final Signal<List<double>> dmcSamples = signal<List<double>>(
    List.generate(_maxSamples, (_) => 0),
  );
  final Signal<double> dmcPeak = signal(0);
  final Signal<double> dmcRMS = signal(0);

  final Signal<AudioChannel> selectedChannel = signal(AudioChannel.pulse1);

  final Signal<bool> pulse1Enabled = signal(true);
  final Signal<bool> pulse2Enabled = signal(true);
  final Signal<bool> triangleEnabled = signal(true);
  final Signal<bool> noiseEnabled = signal(true);
  final Signal<bool> dmcEnabled = signal(true);

  void updateAudioData() {
    final p1Out = apu.pulse1.output().toDouble().clamp(-1.0, 1.0);
    final p2Out = apu.pulse2.output().toDouble().clamp(-1.0, 1.0);
    final triOut = apu.triangle.output().toDouble().clamp(-1.0, 1.0);
    final noiOut = apu.noise.output().toDouble().clamp(-1.0, 1.0);
    final dmcOut = apu.dmc.output().toDouble().clamp(-1.0, 1.0);

    final mixedSample = apu.getOutputSample().clamp(-1.0, 1.0);

    _pulse1Buffer.add(p1Out);
    _pulse2Buffer.add(p2Out);
    _triangleBuffer.add(triOut);
    _noiseBuffer.add(noiOut);
    _dmcBuffer.add(dmcOut);
    _mixedBuffer.add(mixedSample);

    if (_pulse1Buffer.length > _maxSamples) _pulse1Buffer.removeAt(0);
    if (_pulse2Buffer.length > _maxSamples) _pulse2Buffer.removeAt(0);
    if (_triangleBuffer.length > _maxSamples) _triangleBuffer.removeAt(0);
    if (_noiseBuffer.length > _maxSamples) _noiseBuffer.removeAt(0);
    if (_dmcBuffer.length > _maxSamples) _dmcBuffer.removeAt(0);
    if (_mixedBuffer.length > _maxSamples) _mixedBuffer.removeAt(0);

    pulse1Samples.value = List<double>.from(_pulse1Buffer);
    pulse1Peak.value = _calculatePeak(_pulse1Buffer);
    pulse1RMS.value = _calculateRMS(_pulse1Buffer);

    pulse2Samples.value = List<double>.from(_pulse2Buffer);
    pulse2Peak.value = _calculatePeak(_pulse2Buffer);
    pulse2RMS.value = _calculateRMS(_pulse2Buffer);

    triangleSamples.value = List<double>.from(_triangleBuffer);
    trianglePeak.value = _calculatePeak(_triangleBuffer);
    triangleRMS.value = _calculateRMS(_triangleBuffer);

    noiseSamples.value = List<double>.from(_noiseBuffer);
    noisePeak.value = _calculatePeak(_noiseBuffer);
    noiseRMS.value = _calculateRMS(_noiseBuffer);

    dmcSamples.value = List<double>.from(_dmcBuffer);
    dmcPeak.value = _calculatePeak(_dmcBuffer);
    dmcRMS.value = _calculateRMS(_dmcBuffer);

    final mixedAmplitude = mixedSample.abs();
    waveformSamples.value = List<double>.from(_mixedBuffer);
    currentAmplitude.value = mixedAmplitude;
    peakAmplitude.value = _calculatePeak(_mixedBuffer);
    rmsLevel.value = _calculateRMS(_mixedBuffer);
    bufferSize.value = _mixedBuffer.length;
  }

  double _calculatePeak(List<double> buffer) {
    if (buffer.isEmpty) return 0;

    return buffer.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
  }

  double _calculateRMS(List<double> buffer) {
    if (buffer.isEmpty) return 0;

    final sumSquares = buffer.fold<double>(
      0,
      (sum, sample) => sum + (sample * sample),
    );

    return (sumSquares / buffer.length).clamp(0.0, 1.0);
  }

  void enableChannel(AudioChannel channel) {
    switch (channel) {
      case AudioChannel.pulse1:
        pulse1Enabled.value = true;
        apu.pulse1.enable = true;
      case AudioChannel.pulse2:
        pulse2Enabled.value = true;
        apu.pulse2.enable = true;
      case AudioChannel.triangle:
        triangleEnabled.value = true;
        apu.triangle.enable = true;
      case AudioChannel.noise:
        noiseEnabled.value = true;
        apu.noise.enable = true;
      case AudioChannel.dmc:
        dmcEnabled.value = true;

        if (apu.dmc.duration == 0) {
          apu.dmc.duration = apu.dmc.sampleLength;
          apu.dmc.currentAddress = apu.dmc.sampleAddress;
        }
    }
  }

  void disableChannel(AudioChannel channel) {
    switch (channel) {
      case AudioChannel.pulse1:
        pulse1Enabled.value = false;
        apu.pulse1.enable = false;
      case AudioChannel.pulse2:
        pulse2Enabled.value = false;
        apu.pulse2.enable = false;
      case AudioChannel.triangle:
        triangleEnabled.value = false;
        apu.triangle.enable = false;
      case AudioChannel.noise:
        noiseEnabled.value = false;
        apu.noise.enable = false;
      case AudioChannel.dmc:
        dmcEnabled.value = false;
        apu.dmc.duration = 0;
    }
  }

  void toggleChannel(AudioChannel channel) {
    switch (channel) {
      case AudioChannel.pulse1:
        pulse1Enabled.value = !pulse1Enabled.value;
        apu.pulse1.enable = pulse1Enabled.value;
      case AudioChannel.pulse2:
        pulse2Enabled.value = !pulse2Enabled.value;
        apu.pulse2.enable = pulse2Enabled.value;
      case AudioChannel.triangle:
        triangleEnabled.value = !triangleEnabled.value;
        apu.triangle.enable = triangleEnabled.value;
      case AudioChannel.noise:
        noiseEnabled.value = !noiseEnabled.value;
        apu.noise.enable = noiseEnabled.value;
      case AudioChannel.dmc:
        dmcEnabled.value = !dmcEnabled.value;
        if (dmcEnabled.value) {
          if (apu.dmc.duration == 0) {
            apu.dmc.duration = apu.dmc.sampleLength;
            apu.dmc.currentAddress = apu.dmc.sampleAddress;
          }
        } else {
          apu.dmc.duration = 0;
        }
    }
  }

  void dispose() {
    _pulse1Buffer.clear();
    _pulse2Buffer.clear();
    _triangleBuffer.clear();
    _noiseBuffer.clear();
    _dmcBuffer.clear();
    _mixedBuffer.clear();
  }
}
