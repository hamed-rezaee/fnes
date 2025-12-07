import 'package:fnes/components/audio_manager.dart';
import 'package:signals/signals_flutter.dart';

class AudioStateManager {
  AudioStateManager(this._audioPlayer);

  final AudioManager _audioPlayer;
  final Signal<bool> isEnabled = signal(true);

  void toggle() => isEnabled.value ? _disable() : _enable();

  void resumeIfEnabled() {
    if (isEnabled.value) _audioPlayer.resume();
  }

  void pause() => _audioPlayer.pause();

  Future<void> addSamples(List<double> samples) {
    if (isEnabled.value) return _audioPlayer.addSamples(samples);

    return Future.value();
  }

  void _enable() {
    if (!isEnabled.value) {
      isEnabled.value = true;
      _audioPlayer.resume();
    }
  }

  void _disable() {
    if (isEnabled.value) {
      isEnabled.value = false;
      _audioPlayer.pause();
    }
  }

  Future<void> dispose() => _audioPlayer.dispose();
}
