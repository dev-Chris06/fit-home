// La fiche d'un exercice : grande animation, muscle travaillé, conseil et séries.
import 'package:flutter/material.dart';

import '../anim/exercise_view.dart';
import '../data/programme.dart';
import '../theme.dart';

class ExerciseScreen extends StatelessWidget {
  final String exerciseId;
  final String? reps;
  const ExerciseScreen({super.key, required this.exerciseId, this.reps});

  @override
  Widget build(BuildContext context) {
    final ex = exercises[exerciseId]!;
    return Scaffold(
      appBar: AppBar(title: Text(ex.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          AspectRatio(aspectRatio: 1, child: ExerciseView(exerciseId)),
          const SizedBox(height: 16),
          Eyebrow(ex.zone),
          const SizedBox(height: 4),
          Text(ex.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(ex.tip, style: const TextStyle(fontSize: 16, height: 1.4)),
          if (reps != null) ...[
            const SizedBox(height: 12),
            Text(reps!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Palette.main)),
          ],
          const SizedBox(height: 16),
          const Text('Le halo orange montre le muscle travaillé ; la flèche indique le sens du mouvement.',
              style: TextStyle(color: Palette.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
