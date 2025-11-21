import 'dart:async';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

class AudioManager {
  AudioManager({this.sampleRate = 44100});

  final int sampleRate;

  bool _isInitialized = false;
  bool _isPlaying = false;

  final List<double> _audioQueue = [];
  final int _maxBufferSize = 16384;
  final int _chunkSize = 4410;

  late final AudioStream _audioStream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioStream = getAudioStream();

      _audioStream.init(
        sampleRate: sampleRate,
        bufferMilliSec: 500,
      );

      _isInitialized = true;
    } on Exception catch (_) {
      _isInitialized = false;
    }
  }

  double _highPassPrev = 0;
  double _highPassOut = 0;

  void addSamples(List<double> samples) {
    if (!_isInitialized || !_isPlaying) return;

    for (final sample in samples) {
      var normalized = sample - 1.0;

      _highPassOut = normalized - _highPassPrev + 0.996 * _highPassOut;
      _highPassPrev = normalized;
      normalized = _highPassOut;

      final audioSample = (normalized * 0.5).clamp(-1.0, 1.0);
      _audioQueue.add(audioSample);
    }

    while (_audioQueue.length >= _chunkSize) {
      final chunk = Float32List(_chunkSize);
      for (var i = 0; i < _chunkSize; i++) {
        chunk[i] = _audioQueue.removeAt(0);
      }

      try {
        _audioStream.push(chunk);
      } on Exception catch (_) {}
    }

    while (_audioQueue.length > _maxBufferSize) {
      _audioQueue.removeAt(0);
    }
  }

  void pause() {
    if (!_isInitialized) return;

    _isPlaying = false;
    _audioQueue.clear();
    _highPassPrev = 0;
    _highPassOut = 0;
  }

  void resume() {
    if (!_isInitialized) return;

    _isPlaying = true;

    try {
      _audioStream.resume();
    } on Exception catch (_) {}
  }

  void clear() {
    _audioQueue.clear();
    _highPassPrev = 0;
    _highPassOut = 0;
    pause();
  }

  Future<void> dispose() async {
    _audioQueue.clear();
    _isPlaying = false;

    try {
      _audioStream.uninit();
    } on Exception catch (_) {}

    _isInitialized = false;
  }
}
