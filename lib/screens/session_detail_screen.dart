// Le détail d'une séance : format, liste des exercices (avec leur animation), bouton pour la lancer.
import 'package:flutter/material.dart';

import '../anim/exercise_view.dart';
import '../app_state.dart';
import '../data/programme.dart';
import '../data/session_plan.dart';
import '../theme.dart';
import 'exercise_screen.dart';
import 'guided_session_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final SessionDef session;
  const SessionDetailScreen({super.key, required this.session});

  String get _format => switch (session.kind) {
        SessionKind.muscu => '3 séries par exercice, ${restSeconds(app.palier)} s de repos entre les séries. L’échauffement est inclus au début.',
        SessionKind.circuit => '40 s d’effort, 20 s de repos, les 7 exercices à la suite, ${circuitRounds(app.palier)} tours.',
        SessionKind.posture => 'En fin de séance, prends 2 ou 3 mouvements ; la mini-séance complète se fait quand tu veux.',
        SessionKind.warmup => 'Environ 3 minutes, avant chaque séance.',
        SessionKind.variants => 'Le curl marteau remplace le curl biceps une séance A sur deux, la chaise remplace les fentes une séance B sur deux, '
            'et les pompes classiques remplacent les pompes sur les genoux au palier 3.',
      };

  @override
  Widget build(BuildContext context) {
    final items = session.kind == SessionKind.muscu
        ? effectiveItems(session, palier: app.palier, doneCount: app.doneCount(session.id))
        : session.items;
    final canStart = session.kind != SessionKind.variants;
    return Scaffold(
      appBar: AppBar(title: Text(session.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(session.subtitle, style: const TextStyle(color: Palette.muted)),
          const SizedBox(height: 8),
          Text(_format),
          if (canStart) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Commencer'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GuidedSessionScreen(session: session))),
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++) ...[
            Panel(
              padding: const EdgeInsets.all(10),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ExerciseScreen(exerciseId: items[i].exerciseId, reps: items[i].sets > 1 ? '${items[i].sets} × ${items[i].reps}' : items[i].reps))),
              child: Row(children: [
                SizedBox(width: 76, height: 76, child: ExerciseView(items[i].exerciseId, radius: const BorderRadius.all(Radius.circular(12)))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Eyebrow('${i + 1} · ${items[i].exercise.zone}'),
                    const SizedBox(height: 2),
                    Text(items[i].exercise.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(items[i].sets > 1 ? '${items[i].sets} × ${items[i].reps}' : items[i].reps, style: const TextStyle(color: Palette.main, fontSize: 13)),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: Palette.muted),
              ]),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
