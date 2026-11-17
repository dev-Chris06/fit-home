// L'onglet « Plus » : paliers, alimentation, conseils de sécurité et mises à jour.
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../services/update_service.dart';
import '../theme.dart';
import '../widgets/update_dialog.dart';
import 'nutrition_screen.dart';
import 'paliers_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});
  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String version = '…';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => version = i.version);
    }).catchError((_) {});
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) => Panel(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, color: Palette.main),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(sub, style: const TextStyle(color: Palette.muted, fontSize: 13)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Palette.muted),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text('Plus', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _tile(Icons.trending_up, 'Paliers de progression', 'Palier actuel : ${app.palier}',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaliersScreen()))),
          const SizedBox(height: 10),
          _tile(Icons.restaurant_outlined, 'Alimentation', 'Les bases pour se dessiner',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionScreen()))),
          const SizedBox(height: 20),
          const Eyebrow('Sécurité', color: Palette.muted),
          const SizedBox(height: 8),
          const Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('• La technique passe avant la charge : si le mouvement se déforme, arrête la série.'),
              SizedBox(height: 6),
              Text('• Arrête la séance en cas de douleur vive dans une articulation, de vertige ou de douleur dans la poitrine.'),
              SizedBox(height: 6),
              Text('• Une douleur qui dure plusieurs jours mérite l’avis d’un médecin.'),
              SizedBox(height: 6),
              Text('• Les courbatures des premières semaines sont normales : échauffe-toi bien.'),
            ]),
          ),
          const SizedBox(height: 20),
          const Eyebrow('Mises à jour', color: Palette.muted),
          const SizedBox(height: 8),
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Version installée : $version', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.system_update),
                  label: const Text('Rechercher une mise à jour'),
                  onPressed: () => runUpdateCheck(context),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: app.autoUpdateCheck,
                onChanged: app.setAutoUpdateCheck,
                title: const Text('Vérifier automatiquement au démarrage'),
                subtitle: const Text('Une fois par jour, seulement si internet est disponible', style: TextStyle(color: Palette.muted)),
              ),
              TextButton(
                onPressed: () => launchUrl(Uri.parse(releasesPageUrl), mode: LaunchMode.externalApplication),
                child: const Text('Voir toutes les versions sur GitHub'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
