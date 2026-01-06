import 'dart:async';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

class AudioManager {
  AudioManager({this.sampleRate = 44100});

  final int sampleRate;

  bool _isInitialized = false;
  bool _isPlaying = false;

  final List<double> _audioQueue = [];

  final int _maxBufferSize = 0x8000;
  final int _chunkSize = 0x0800;
  final int _minBufferThreshold = 0x0400;

  double _volume = 1;

  late final AudioStream _audioStream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioStream = getAudioStream();

      _audioStream.init(sampleRate: sampleRate);

      _isInitialized = true;
    } on Exception catch (_) {
      _isInitialized = false;
    }
  }

  Future<void> addSamples(List<double> samples) async {
    if (!_isInitialized || !_isPlaying) return;

    await Future.microtask(() {
      for (final sample in samples) {
        final audioSample = (sample * _volume).clamp(-1.0, 1.0);
        _audioQueue.add(audioSample);
      }

      if (_audioQueue.length >= _minBufferThreshold) {
        while (_audioQueue.length >= _chunkSize) {
          final chunk = Float32List.fromList(
            _audioQueue.getRange(0, _chunkSize).toList(),
          );

          _audioQueue.removeRange(0, _chunkSize);

          try {
            _audioStream.push(chunk);
          } on Exception catch (_) {
            _audioQueue.insertAll(0, chunk);
            break;
          }
        }
      }

      if (_audioQueue.length > _maxBufferSize) {
        final overflow = _audioQueue.length - _maxBufferSize;

        _audioQueue.removeRange(0, overflow);
      }
    });
  }

  void pause() {
    if (!_isInitialized) return;

    _isPlaying = false;

    _audioQueue.clear();
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

    pause();
  }

  void setVolume(double volume) => _volume = volume.clamp(0.0, 1.0);

  double get volume => _volume;

  double get bufferFillPercentage =>
      _isInitialized ? (_audioQueue.length / _maxBufferSize) : 0.0;

  int get bufferedSamples => _audioQueue.length;

  Future<void> dispose() async {
    _audioQueue.clear();
    _isPlaying = false;

    try {
      _audioStream.uninit();
    } on Exception catch (_) {}

    _isInitialized = false;
  }
}
