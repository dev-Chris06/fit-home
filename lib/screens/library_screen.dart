// La bibliothèque : tous les exercices, filtrables par famille et par palier.
import 'package:material_ui/material_ui.dart';

import '../anim/exercise_view.dart';
import '../data/programme.dart';
import '../theme.dart';
import 'exercise_screen.dart';
import 'session_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? group; // null = toutes les familles
  int? level; // null = tous les paliers

  @override
  Widget build(BuildContext context) {
    final list = exercises.values.where((e) => (group == null || e.group == group) && (level == null || e.level == level)).toList()
      ..sort((a, b) {
        final g = Groups.all.indexOf(a.group).compareTo(Groups.all.indexOf(b.group));
        if (g != 0) return g;
        return a.level != b.level ? a.level.compareTo(b.level) : a.name.compareTo(b.name);
      });
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        sliver: SliverList.list(children: [
          const Text('Exercices', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${exercises.length} exercices. Pour en mettre un dans une séance, ouvre la séance et touche le bouton à double flèche à côté d’un exercice.',
              style: const TextStyle(color: Palette.muted)),
          const SizedBox(height: 12),
          Wrap(runSpacing: 6, children: [
            _chip('Toutes', group == null, () => setState(() => group = null)),
            for (final g in Groups.all) _chip(g, group == g, () => setState(() => group = g)),
          ]),
          const SizedBox(height: 10),
          Wrap(runSpacing: 6, children: [
            _chip('Tous niveaux', level == null, () => setState(() => level = null)),
            for (final l in const [1, 2, 3]) _chip('Palier $l', level == l, () => setState(() => level = l)),
          ]),
          const SizedBox(height: 12),
        ]),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = list[i];
            return Panel(
              padding: const EdgeInsets.all(8),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseScreen(exerciseId: e.id, reps: e.reps))),
              child: Row(children: [
                SizedBox(width: 72, height: 72, child: ExerciseView(e.id, radius: const BorderRadius.all(Radius.circular(12)))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Eyebrow(e.zone),
                    Text(e.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(e.group, style: const TextStyle(color: Palette.muted, fontSize: 13)),
                  ]),
                ),
                LevelBadge(e.level),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), showCheckmark: false),
      );
}
