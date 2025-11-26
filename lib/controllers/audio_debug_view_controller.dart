import 'package:fnes/components/apu.dart';
import 'package:signals/signals_flutter.dart';

class AudioDebugViewController {
  AudioDebugViewController({required this.apu}) {
    _updateTimer();
  }

  final APU apu;
  final List<double> _sampleBuffer = [];
  static const int _maxSamples = 256;
  static const int _updateIntervalMs = 50;

  final Signal<List<double>> waveformSamples = signal<List<double>>([]);
  final Signal<double> currentAmplitude = signal(0);
  final Signal<double> peakAmplitude = signal(0);
  final Signal<double> rmsLevel = signal(0);
  final Signal<int> bufferSize = signal(0);

  void _updateTimer() {
    Future.delayed(const Duration(milliseconds: _updateIntervalMs), () {
      updateAudioData();
      _updateTimer();
    });
  }

  void updateAudioData() {
    final lastSample = apu.getOutputSample().clamp(-1.0, 1.0);

    _sampleBuffer.add(lastSample);

    if (_sampleBuffer.length > _maxSamples) _sampleBuffer.removeAt(0);

    final amplitude = lastSample.abs();
    final peakAmpl = _sampleBuffer.isEmpty
        ? 0.0
        : _sampleBuffer.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);

    final rms = _calculateRMS();

    waveformSamples.value = List<double>.from(_sampleBuffer);
    currentAmplitude.value = amplitude;
    peakAmplitude.value = peakAmpl;
    rmsLevel.value = rms;
    bufferSize.value = _sampleBuffer.length;
  }

  double _calculateRMS() {
    if (_sampleBuffer.isEmpty) return 0;

    final sumSquares =
        _sampleBuffer.fold<double>(0, (sum, sample) => sum + (sample * sample));

    return (sumSquares / _sampleBuffer.length).clamp(0.0, 1.0);
  }

  void dispose() => _sampleBuffer.clear();
}
