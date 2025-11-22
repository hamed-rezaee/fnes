class AudioDebugViewState {
  AudioDebugViewState({
    required this.waveformSamples,
    required this.currentAmplitude,
    required this.peakAmplitude,
    required this.rmsLevel,
    required this.bufferSize,
  });

  factory AudioDebugViewState.initial() => AudioDebugViewState(
        waveformSamples: [],
        currentAmplitude: 0,
        peakAmplitude: 0,
        rmsLevel: 0,
        bufferSize: 0,
      );

  final List<double> waveformSamples;
  final double currentAmplitude;
  final double peakAmplitude;
  final double rmsLevel;
  final int bufferSize;

  AudioDebugViewState copyWith({
    List<double>? waveformSamples,
    double? currentAmplitude,
    double? peakAmplitude,
    double? rmsLevel,
    int? bufferSize,
  }) =>
      AudioDebugViewState(
        waveformSamples: waveformSamples ?? this.waveformSamples,
        currentAmplitude: currentAmplitude ?? this.currentAmplitude,
        peakAmplitude: peakAmplitude ?? this.peakAmplitude,
        rmsLevel: rmsLevel ?? this.rmsLevel,
        bufferSize: bufferSize ?? this.bufferSize,
      );
}
