// Le détail d'une séance : format, liste des exercices (avec leur animation), bouton pour la lancer,
// et le bouton « Remplacer » pour changer un exercice par un autre de la bibliothèque.
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
    final canStart = session.kind != SessionKind.variants;
    final canReplace = session.kind != SessionKind.variants;
    return Scaffold(
      appBar: AppBar(title: Text(session.title)),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final subs = app.subsFor(session.id);
          final items = effectiveItems(session, palier: app.palier, doneCount: app.doneCount(session.id), subs: subs);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Text(session.subtitle, style: const TextStyle(color: Palette.muted)),
              const SizedBox(height: 8),
              Text(_format),
              if (canReplace) ...[
                const SizedBox(height: 6),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Touche '),
                    WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.swap_horiz, size: 18, color: Palette.muted)),
                    TextSpan(text: ' pour remplacer un exercice par un autre de la même famille.'),
                  ]),
                  style: TextStyle(color: Palette.muted, fontSize: 13),
                ),
              ],
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
                _ItemTile(
                  index: i,
                  item: items[i],
                  originalId: session.items[i].exerciseId,
                  replaced: subs.containsKey(session.items[i].exerciseId),
                  onReplace: canReplace
                      ? () => showReplaceSheet(context, session.id, session.items[i].exerciseId, items[i].exerciseId)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final int index;
  final SessionItem item;
  final String originalId;
  final bool replaced;
  final VoidCallback? onReplace;
  const _ItemTile({required this.index, required this.item, required this.originalId, required this.replaced, this.onReplace});

  @override
  Widget build(BuildContext context) {
    final repsText = item.sets > 1 ? '${item.sets} × ${item.reps}' : item.reps;
    return Panel(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseScreen(exerciseId: item.exerciseId, reps: repsText))),
      child: Row(children: [
        SizedBox(width: 76, height: 76, child: ExerciseView(item.exerciseId, radius: const BorderRadius.all(Radius.circular(12)))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow('${index + 1} · ${item.exercise.zone}'),
            const SizedBox(height: 2),
            Text(item.exercise.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(repsText, style: const TextStyle(color: Palette.main, fontSize: 13)),
            if (replaced)
              Text('Remplace : ${exercises[originalId]?.name ?? originalId}', style: const TextStyle(color: Palette.muted, fontSize: 12)),
          ]),
        ),
        if (onReplace != null) IconButton(icon: const Icon(Icons.swap_horiz), tooltip: 'Remplacer', onPressed: onReplace),
      ]),
    );
  }
}

/// La feuille « Remplacer » : les exercices de la même famille, et le retour à l'exercice d'origine.
Future<void> showReplaceSheet(BuildContext context, String sessionId, String originalId, String currentId) {
  final original = exercises[originalId]!;
  final candidates = exercises.values.where((e) => e.group == original.group && e.id != currentId).toList()
    ..sort((a, b) => a.level != b.level ? a.level.compareTo(b.level) : a.name.compareTo(b.name));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    showDragHandle: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Remplacer « ${exercises[currentId]?.name ?? currentId} »', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Famille : ${original.group}. Le nombre de séries reste le même.', style: const TextStyle(color: Palette.muted)),
          const SizedBox(height: 12),
          if (currentId != originalId) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.undo),
              label: Text('Revenir à « ${original.name} »'),
              onPressed: () {
                app.setSub(sessionId, originalId, null);
                Navigator.pop(sheet);
              },
            ),
            const SizedBox(height: 12),
          ],
          for (final e in candidates) ...[
            Material(
              color: Palette.ground,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  app.setSub(sessionId, originalId, e.id);
                  Navigator.pop(sheet);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('« ${e.name} » ajouté à la séance.')));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    SizedBox(width: 64, height: 64, child: ExerciseView(e.id, radius: const BorderRadius.all(Radius.circular(10)))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${e.zone} · ${e.reps}', style: const TextStyle(color: Palette.muted, fontSize: 13)),
                      ]),
                    ),
                    LevelBadge(e.level),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    ),
  );
}

/// Le badge de niveau : palier 1, 2 ou 3.
class LevelBadge extends StatelessWidget {
  final int level;
  const LevelBadge(this.level, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = switch (level) { 1 => Palette.main, 2 => const Color(0xFFFFC857), _ => Palette.accent };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(99)),
      child: Text('Palier $level', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
