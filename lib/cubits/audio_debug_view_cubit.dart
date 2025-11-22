import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fnes/components/apu.dart';
import 'package:fnes/cubits/audio_debug_view_state.dart';

class AudioDebugViewCubit extends Cubit<AudioDebugViewState> {
  AudioDebugViewCubit({required this.apu})
      : super(AudioDebugViewState.initial()) {
    _updateTimer();
  }

  final APU apu;
  final List<double> _sampleBuffer = [];
  static const int _maxSamples = 256;
  static const int _updateIntervalMs = 50;

  void _updateTimer() {
    Future.delayed(const Duration(milliseconds: _updateIntervalMs), () {
      if (!isClosed) {
        updateAudioData();
        _updateTimer();
      }
    });
  }

  void updateAudioData() {
    final lastSample = apu.getOutputSample().clamp(-1.0, 1.0);
    _sampleBuffer.add(lastSample);

    if (_sampleBuffer.length > _maxSamples) {
      _sampleBuffer.removeAt(0);
    }

    final amplitude = lastSample.abs();
    final peakAmplitude = _sampleBuffer.isEmpty
        ? 0.0
        : _sampleBuffer.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);

    final rmsLevel = _calculateRMS();

    emit(
      state.copyWith(
        waveformSamples: List<double>.from(_sampleBuffer),
        currentAmplitude: amplitude,
        peakAmplitude: peakAmplitude,
        rmsLevel: rmsLevel,
        bufferSize: _sampleBuffer.length,
      ),
    );
  }

  double _calculateRMS() {
    if (_sampleBuffer.isEmpty) return 0;

    final sumSquares = _sampleBuffer.fold<double>(
      0,
      (sum, sample) => sum + (sample * sample),
    );

    return (sumSquares / _sampleBuffer.length).clamp(0.0, 1.0);
  }

  @override
  Future<void> close() {
    _sampleBuffer.clear();

    return super.close();
  }
}
