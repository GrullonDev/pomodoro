import 'dart:math';

class BreakActivity {
  final String emoji;
  final String title;
  final String description;
  final int suggestedMinutes;

  const BreakActivity({
    required this.emoji,
    required this.title,
    required this.description,
    required this.suggestedMinutes,
  });

  static const List<BreakActivity> all = [
    BreakActivity(
      emoji: '💧',
      title: 'Hidrátate',
      description: 'Toma un vaso de agua.\nTu cerebro lo agradecerá.',
      suggestedMinutes: 1,
    ),
    BreakActivity(
      emoji: '🤸',
      title: 'Estira el cuerpo',
      description: 'Levántate y estira cuello,\nhombros y espalda.',
      suggestedMinutes: 2,
    ),
    BreakActivity(
      emoji: '🫁',
      title: 'Respira profundo',
      description: 'Inhala 4s · Sostén 4s · Exhala 6s.\nRepite 3 veces.',
      suggestedMinutes: 2,
    ),
    BreakActivity(
      emoji: '👀',
      title: 'Descansa los ojos',
      description: 'Mira un punto lejano por 20 segundos.\nRegla 20-20-20.',
      suggestedMinutes: 1,
    ),
    BreakActivity(
      emoji: '🚶',
      title: 'Camina un poco',
      description: 'Da una vuelta corta.\nMover el cuerpo reactiva la mente.',
      suggestedMinutes: 5,
    ),
    BreakActivity(
      emoji: '🧘',
      title: 'Momento mindful',
      description: 'Cierra los ojos y observa\ntus pensamientos sin juzgar.',
      suggestedMinutes: 2,
    ),
    BreakActivity(
      emoji: '☕',
      title: 'Pausa con café',
      description: 'Prepárate algo caliente.\nDisfruta sin pantallas.',
      suggestedMinutes: 3,
    ),
    BreakActivity(
      emoji: '🌿',
      title: 'Mira por la ventana',
      description: 'Observa algo natural: plantas,\nnubes o el cielo.',
      suggestedMinutes: 2,
    ),
  ];

  static BreakActivity random() => all[Random().nextInt(all.length)];

  static BreakActivity forBreakMinutes(int minutes) {
    if (minutes <= 3) return all[Random().nextInt(4)]; // short activities
    return all[Random().nextInt(all.length)];
  }
}
