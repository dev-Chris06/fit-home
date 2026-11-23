// Les bases de l'alimentation, consultables hors connexion.
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  static const _rules = [
    (Icons.egg_alt_outlined, 'Des protéines à chaque repas', 'Œufs, poisson, poulet, haricots, niébé, fromage de soja (wagassi), arachides en petite quantité.'),
    (Icons.eco_outlined, 'Des légumes à chaque repas', 'La moitié de l’assiette si possible, en sauce ou en accompagnement.'),
    (Icons.rice_bowl_outlined, 'Des féculents en portion raisonnable', 'Riz, pâte, igname, gari : pas de suppression, juste des portions modérées.'),
    (Icons.no_drinks_outlined, 'À limiter', 'Boissons sucrées, sodas, beignets et fritures fréquentes.'),
    (Icons.water_drop_outlined, 'De l’eau', 'Une bouteille à portée de main, surtout les jours de séance et par forte chaleur.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alimentation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const Text('Pour se dessiner, l’assiette compte autant que les séances : des protéines à chaque repas, moins de sucre et de friture.',
              style: TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(height: 16),
          for (final r in _rules) ...[
            Panel(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(r.$1, color: Palette.main),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(r.$3, style: const TextStyle(color: Palette.muted, height: 1.35)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          const Text('Pas besoin de compléments : une alimentation régulière et variée suffit pour ce programme.', style: TextStyle(color: Palette.muted)),
        ],
      ),
    );
  }
}
