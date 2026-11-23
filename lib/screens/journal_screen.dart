// L'onglet Progrès : toutes les séances faites, le palier actuel et le conseil de progression.
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'log_form_screen.dart';
import 'paliers_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  Future<void> _delete(BuildContext context, JournalEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Palette.surface,
        title: const Text('Supprimer cette séance ?'),
        content: Text('${sessionLabel(e.type)} du ${frDate(e.date)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) await app.deleteEntry(e.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une séance'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogFormScreen())),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final list = app.sortedEntries;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            children: [
              const Text('Progrès', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Chaque séance terminée s’enregistre ici toute seule. C’est grâce à cet historique que l’app choisit ta prochaine séance '
                  '(A, puis B, puis C), alterne les variantes et te dit quand passer au palier suivant.',
                  style: TextStyle(color: Palette.muted, height: 1.35)),
              const SizedBox(height: 14),
              Row(children: [
                StatTile('${app.entries.length}', 'séances notées'),
                const SizedBox(width: 10),
                StatTile('${app.last7Days}', 'ces 7 derniers jours'),
                const SizedBox(width: 10),
                StatTile('${app.palier}', 'palier actuel'),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Eyebrow('Mon palier', color: Palette.muted)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaliersScreen())),
                  child: const Text('C’est quoi ?'),
                ),
              ]),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 · Technique')),
                  ButtonSegment(value: 2, label: Text('2 · Charge')),
                  ButtonSegment(value: 3, label: Text('3 · Intensité')),
                ],
                selected: {app.palier},
                showSelectedIcon: false,
                onSelectionChanged: (s) => app.setPalier(s.first),
              ),
              const SizedBox(height: 12),
              AdviceBanner(app.palierAdvice, app.palier),
              const SizedBox(height: 16),
              const Eyebrow('Historique', color: Palette.muted),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Aucune séance pour l’instant. Lance la séance A depuis l’accueil : elle s’enregistrera ici à la fin. '
                      'Une séance faite sans l’app ? Ajoute-la avec le bouton en bas.', style: TextStyle(color: Palette.muted)),
                ),
              for (final e in list) ...[
                Panel(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFF173F35), borderRadius: BorderRadius.circular(10)),
                      child: Text(e.type == 'P' ? 'Post.' : e.type,
                          style: TextStyle(color: Palette.main, fontWeight: FontWeight.w800, fontSize: e.type == 'P' ? 12 : 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          Text('${sessionLabel(e.type)} · ${frDate(e.date)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (e.reussi) const _Pill('Réussie', Palette.main),
                          if (e.ressenti == 'dur') const _Pill('Dur', Palette.accent),
                        ]),
                        Text(
                          ['Ressenti : ${e.ressenti}', if (e.charge.isNotEmpty) 'Charge : ${e.charge}', 'Palier ${e.palier}'].join(' · '),
                          style: const TextStyle(color: Palette.muted, fontSize: 13),
                        ),
                        if (e.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(e.notes)),
                      ]),
                    ),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Palette.muted), tooltip: 'Supprimer', onPressed: () => _delete(context, e)),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
