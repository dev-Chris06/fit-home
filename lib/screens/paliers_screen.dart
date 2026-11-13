// Les trois paliers de progression, et le choix du palier actuel.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/programme.dart';
import '../theme.dart';

class PaliersScreen extends StatelessWidget {
  const PaliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paliers de progression')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const Text('Tu passes au palier suivant quand tu réussis toutes les séries proprement, pas à une date fixe.'),
            const SizedBox(height: 16),
            for (final p in paliers) ...[
              Panel(
                color: p.level == app.palier ? const Color(0xFF173F35) : Palette.surface,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Eyebrow('Palier ${p.level}${p.level == app.palier ? ' · actuel' : ''}', color: Palette.main)),
                    if (p.level != app.palier) TextButton(onPressed: () => app.setPalier(p.level), child: const Text('Choisir')),
                  ]),
                  Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(p.what),
                  const SizedBox(height: 8),
                  Text('Pour passer au suivant : ${p.passIf}', style: const TextStyle(color: Palette.muted, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
