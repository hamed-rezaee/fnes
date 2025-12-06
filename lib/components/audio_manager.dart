import 'dart:async';
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

class AudioManager {
  AudioManager({this.sampleRate = 44100});

  final int sampleRate;

  bool _isInitialized = false;
  bool _isPlaying = false;

  final List<double> _audioQueue = [];
  final int _maxBufferSize = 0x2000;
  final int _chunkSize = 0x0800;

  late final AudioStream _audioStream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioStream = getAudioStream();

      _audioStream.init(
        sampleRate: sampleRate,
        bufferMilliSec: 0xC8,
      );

      _isInitialized = true;
    } on Exception catch (_) {
      _isInitialized = false;
    }
  }

  Future<void> addSamples(List<double> samples) async {
    if (!_isInitialized || !_isPlaying) return;

    await Future.microtask(() {
      for (final sample in samples) {
        final audioSample = sample.clamp(-1.0, 1.0);
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
        _audioQueue.removeRange(0, _audioQueue.length - _maxBufferSize);
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

  Future<void> dispose() async {
    _audioQueue.clear();
    _isPlaying = false;

    try {
      _audioStream.uninit();
    } on Exception catch (_) {}

    _isInitialized = false;
  }
}
