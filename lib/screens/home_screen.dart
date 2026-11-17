// Accueil : la prochaine séance de la rotation, un bouton pour la lancer, et les statistiques.
import 'package:flutter/material.dart';

import '../anim/exercise_view.dart';
import '../app_state.dart';
import '../data/programme.dart';
import '../data/session_plan.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'guided_session_screen.dart';
import 'session_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenSessions;
  const HomeScreen({super.key, required this.onOpenJournal, required this.onOpenSessions});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final next = sessionById(app.nextSession);
        final plan = buildPlan(next, palier: app.palier, doneCount: app.doneCount(next.id));
        final firstId = effectiveItems(next, palier: app.palier, doneCount: app.doneCount(next.id)).first.exerciseId;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Eyebrow('Programme maison · rotation A, B, C', color: Palette.muted),
            const SizedBox(height: 4),
            const Text('Fit Home', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Panel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('Prochaine séance', color: Palette.main),
                            Text(next.id, style: const TextStyle(fontSize: 56, height: 1.1, fontWeight: FontWeight.w800, color: Palette.main)),
                            Text(next.subtitle, style: const TextStyle(color: Palette.muted)),
                            const SizedBox(height: 4),
                            Text('Environ ${estimatedMinutes(plan)} min avec l’échauffement', style: const TextStyle(color: Palette.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      SizedBox(width: 110, height: 110, child: ExerciseView(firstId)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Commencer la séance ${next.id}'),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GuidedSessionScreen(session: next))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionDetailScreen(session: next))),
                      child: const Text('Voir les exercices'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    StatTile('${app.entries.length}', 'séances notées'),
                    const SizedBox(width: 10),
                    StatTile('${app.last7Days}', 'ces 7 derniers jours'),
                    const SizedBox(width: 10),
                    StatTile('${app.palier}', 'palier actuel'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdviceBanner(app.palierAdvice, app.palier),
            if (app.palierAdvice != null) const SizedBox(height: 12),
            Panel(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuidedSessionScreen(session: sessionP))),
              child: const Row(children: [
                Icon(Icons.self_improvement, color: Palette.main),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Posture et souplesse', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('10 minutes, même un jour sans sport', style: TextStyle(color: Palette.muted, fontSize: 13)),
                  ]),
                ),
                Icon(Icons.chevron_right, color: Palette.muted),
              ]),
            ),
            const SizedBox(height: 12),
            Panel(
              onTap: onOpenJournal,
              child: const Row(children: [
                Icon(Icons.insights, color: Palette.main),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Mes progrès', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Historique des séances et palier', style: TextStyle(color: Palette.muted, fontSize: 13)),
                  ]),
                ),
                Icon(Icons.chevron_right, color: Palette.muted),
              ]),
            ),
            const SizedBox(height: 12),
            Panel(
              onTap: onOpenSessions,
              child: const Row(children: [
                Icon(Icons.list_alt, color: Palette.main),
                SizedBox(width: 12),
                Expanded(child: Text('Toutes les séances et les 32 exercices', style: TextStyle(fontWeight: FontWeight.w700))),
                Icon(Icons.chevron_right, color: Palette.muted),
              ]),
            ),
          ],
        );
      },
    );
  }
}
