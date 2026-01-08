import 'package:flutter/material.dart';
import 'package:pomodoro/features/audio/domain/ambient_sound.dart';

class AudioRepository {
  static const List<AmbientSound> allSounds = [
    AmbientSound(
      id: 'rain',
      name: 'Lluvia',
      assetPath:
          'sounds/cronometro.mp3', // Placeholder, user needs 'sounds/rain.mp3'
      icon: Icons.water_drop,
      baseColor: Colors.blueAccent,
    ),
    AmbientSound(
      id: 'fire',
      name: 'Fuego',
      assetPath: 'sounds/cronometro.mp3', // Placeholder
      icon: Icons.local_fire_department,
      baseColor: Colors.orangeAccent,
    ),
    AmbientSound(
      id: 'forest',
      name: 'Bosque',
      assetPath: 'sounds/cronometro.mp3', // Placeholder
      icon: Icons.forest,
      baseColor: Colors.green,
    ),
    AmbientSound(
      id: 'cafe',
      name: 'Cafetería',
      assetPath: 'sounds/cronometro.mp3', // Placeholder
      icon: Icons.coffee,
      baseColor: Colors.brown,
    ),
  ];
}
