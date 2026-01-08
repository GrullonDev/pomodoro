import 'package:flutter/material.dart';

class AmbientSound {
  final String id;
  final String name;
  final String assetPath;
  final IconData icon;
  final Color baseColor;

  const AmbientSound({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.icon,
    required this.baseColor,
  });
}
