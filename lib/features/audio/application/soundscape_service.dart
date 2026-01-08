import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:pomodoro/features/audio/domain/ambient_sound.dart';

class SoundscapeService {
  SoundscapeService._();
  static final SoundscapeService instance = SoundscapeService._();

  // Active players: Map<SoundId, AudioPlayer>
  final Map<String, AudioPlayer> _activePlayers = {};
  final Map<String, double> _volumes = {};

  final ValueNotifier<List<String>> activeSoundIds = ValueNotifier([]);

  Future<void> stopAll() async {
    for (var player in _activePlayers.values) {
      await player.stop();
      await player.dispose();
    }
    _activePlayers.clear();
    _volumes.clear();
    activeSoundIds.value = [];
  }

  Future<void> toggleSound(AmbientSound sound) async {
    if (_activePlayers.containsKey(sound.id)) {
      // Stop and remove
      final p = _activePlayers.remove(sound.id);
      await p?.stop();
      await p?.dispose();
      _volumes.remove(sound.id);
    } else {
      // Start
      final p = AudioPlayer(playerId: 'ambience_${sound.id}');
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setSource(AssetSource(sound.assetPath));
      await p.setVolume(_volumes[sound.id] ?? 0.5);
      await p.resume();
      _activePlayers[sound.id] = p;
      _volumes[sound.id] = 0.5;
    }
    activeSoundIds.value = _activePlayers.keys.toList();
  }

  Future<void> setVolume(String soundId, double volume) async {
    _volumes[soundId] = volume;
    final p = _activePlayers[soundId];
    if (p != null) {
      await p.setVolume(volume);
    }
  }

  bool isPlaying(String soundId) => _activePlayers.containsKey(soundId);
  double getVolume(String soundId) => _volumes[soundId] ?? 0.5;
}
