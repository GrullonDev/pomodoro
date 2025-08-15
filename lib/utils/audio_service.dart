import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:pomodoro/core/di/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple singleton AudioService to centralize audio players and reduce
/// repeated creation/disposal which can trigger platform MediaPlayer errors
/// and increase memory churn.
class AudioService {
  AudioService._internal() {
    _sfxPlayer = AudioPlayer(playerId: 'sfx');
    _tickPlayer = AudioPlayer(playerId: 'tick');
  }

  static final AudioService instance = AudioService._internal();

  late final AudioPlayer _sfxPlayer;
  late final AudioPlayer _tickPlayer;
  bool _preloaded = false;
  static const _focusTrackKey = 'focus_track_asset';
  String? _cachedFocusTrack; // asset path
  Uint8List? _generatedBeep;

  Future<void> preload() async {
    if (_preloaded) return;
    try {
      await _sfxPlayer.setSource(AssetSource('sounds/last5.mp3'));
      _preloaded = true;
    } catch (e) {
      // Best-effort fallback to generated beep bytes
      _generatedBeep ??= _generateBeepWav();
      try {
        await _sfxPlayer.setSource(BytesSource(_generatedBeep!));
        _preloaded = true;
      } catch (_) {
        // swallow: we still want the app to keep running
      }
    }
  }

  Future<void> playLast5() async {
    try {
      if (!_preloaded) await preload();
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(0.8);
      await _sfxPlayer.resume();
    } catch (e) {
      // ignore - keep app robust
    }
  }

  Future<List<String>> availableFocusTracks() async {
    // Hardcode list of bundled assets for now; could be loaded from manifest.
    return [
      'sounds/cronometro.mp3',
      'sounds/forest.mp3',
      'sounds/rain.mp3',
      'sounds/white_noise.mp3',
    ];
  }

  Future<void> setFocusTrack(String assetPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_focusTrackKey, assetPath);
    _cachedFocusTrack = assetPath;
  }

  Future<String> getFocusTrack() async {
    if (_cachedFocusTrack != null) return _cachedFocusTrack!;
    final prefs = await SharedPreferences.getInstance();
    _cachedFocusTrack = prefs.getString(_focusTrackKey) ?? 'sounds/cronometro.mp3';
    return _cachedFocusTrack!;
  }

  Future<void> startTicking() async {
    try {
      await _tickPlayer.setReleaseMode(ReleaseMode.loop);
      await _tickPlayer.setVolume(0.35);
      final track = await getFocusTrack();
      await _tickPlayer.setSource(AssetSource(track));
      await _tickPlayer.resume();
    } catch (e) {
      // ignore
    }
  }

  Future<void> stopTicking() async {
    try {
      await _tickPlayer.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _sfxPlayer.dispose();
    } catch (_) {}
    try {
      await _tickPlayer.dispose();
    } catch (_) {}
  }

  // Generate a short beep WAV
  Uint8List _generateBeepWav({
    double freq = 440,
    int sampleRate = 44100,
    int millis = 500,
  }) {
    final sampleCount = (sampleRate * millis / 1000).round();
    final data = BytesBuilder();
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final sample = (sin(2 * pi * freq * t) * 0.4);
      final s = (sample * 32767).clamp(-32768, 32767).toInt();
      data.addByte(s & 0xFF);
      data.addByte((s >> 8) & 0xFF);
    }
    final dataBytes = data.toBytes();
    final totalDataLen = dataBytes.length + 36;
    final header = BytesBuilder();
    void writeString(String s) => header.add(s.codeUnits);
    void write32(int v) => header
        .add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
    void write16(int v) => header.add([v & 0xFF, (v >> 8) & 0xFF]);
    writeString('RIFF');
    write32(totalDataLen);
    writeString('WAVE');
    writeString('fmt ');
    write32(16);
    write16(1);
    write16(1);
    write32(sampleRate);
    write32(sampleRate * 2);
    write16(2);
    write16(16);
    writeString('data');
    write32(dataBytes.length);
    final bytes = BytesBuilder();
    bytes.add(header.toBytes());
    bytes.add(dataBytes);
    return bytes.toBytes();
  }
}
