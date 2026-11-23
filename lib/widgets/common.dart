// Petits outils partagés par les écrans : dates en français, libellés, tuiles de statistiques.
import 'package:material_ui/material_ui.dart';

import '../data/programme.dart';
import '../theme.dart';

const _days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// « 2026-11-13 » → « ven. 13 nov. »
String frDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

String sessionLabel(String type) => switch (type) {
      'A' => 'Séance A',
      'B' => 'Séance B',
      'C' => 'Séance C',
      'P' => 'Posture',
      _ => type,
    };

String sessionSubtitle(String type) => sessionById(type).subtitle;

class StatTile extends StatelessWidget {
  final String value;
  final String label;
  const StatTile(this.value, this.label, {super.key});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Palette.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
            Text(label, style: const TextStyle(fontSize: 12, color: Palette.muted)),
          ],
        ),
      ),
    );
  }
}

/// Le bandeau de conseil de palier (monter ou alléger).
class AdviceBanner extends StatelessWidget {
  final String? advice;
  final int palier;
  const AdviceBanner(this.advice, this.palier, {super.key});
  @override
  Widget build(BuildContext context) {
    if (advice == null) return const SizedBox.shrink();
    final up = advice == 'up';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: up ? const Color(0xFF173F35) : const Color(0xFF3A2320),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(up ? Icons.trending_up : Icons.self_improvement, color: up ? Palette.main : Palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(up
                ? 'Tes 3 dernières séances sont réussies proprement : tu peux passer au palier ${palier + 1}. Change-le dans Progrès quand tu te sens prêt.'
                : 'Deux séances dures de suite : allège un peu la charge ou fais 2 séries au lieu de 3 la prochaine fois.'),
          ),
        ],
      ),
    );
  }
}
