// La liste des séances : échauffement, A, B, C, posture et variantes.
import 'package:material_ui/material_ui.dart';

import '../data/programme.dart';
import '../theme.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: allSessions.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Séances', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          );
        }
        final s = allSessions[i - 1];
        final badge = s.id.length == 1 && 'ABC'.contains(s.id) ? s.id : (s.id == 'P' ? 'P' : (s.id == 'E' ? 'É' : 'V'));
        return Panel(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionDetailScreen(session: s))),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF173F35), borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Palette.main)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(s.subtitle, style: const TextStyle(color: Palette.muted, fontSize: 13)),
              ]),
            ),
            Text('${s.items.length}', style: const TextStyle(color: Palette.muted)),
            const Icon(Icons.chevron_right, color: Palette.muted),
          ]),
        );
      },
    );
  }
}
