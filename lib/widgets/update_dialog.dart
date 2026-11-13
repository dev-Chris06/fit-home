// L'interface de la recherche de mise à jour : un dialogue qui propose de télécharger la nouvelle version.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../services/update_service.dart';
import '../theme.dart';

/// [silent] = vérification automatique au démarrage : on n'affiche rien s'il n'y a pas de nouveauté ou pas de réseau.
Future<void> runUpdateCheck(BuildContext context, {bool silent = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!silent) {
    messenger.showSnackBar(const SnackBar(content: Text('Recherche d’une mise à jour…'), duration: Duration(seconds: 2)));
  }
  try {
    final info = await checkForUpdate();
    await app.markUpdateChecked();
    if (!context.mounted) return;
    if (info.available) {
      await showDialog<void>(context: context, builder: (_) => _UpdateDialog(info));
    } else if (!silent) {
      messenger.showSnackBar(SnackBar(content: Text('Tu as la dernière version (${info.current}).')));
    }
  } on UpdateException catch (e) {
    if (!silent) messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    if (!silent) messenger.showSnackBar(const SnackBar(content: Text('La recherche de mise à jour a échoué. Réessaie plus tard.')));
  }
}

class _UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  const _UpdateDialog(this.info);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.surface,
      title: Text('Version ${info.latest} disponible'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tu as la version ${info.current}.', style: const TextStyle(color: Palette.muted)),
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Eyebrow('Nouveautés', color: Palette.main),
              const SizedBox(height: 6),
              Text(info.notes),
            ],
            const SizedBox(height: 12),
            const Text(
              'Le téléchargement s’ouvre dans ton navigateur. Ouvre ensuite le fichier fit-home.apk pour installer la mise à jour : '
              'ton journal et tes réglages sont conservés.',
              style: TextStyle(color: Palette.muted, fontSize: 13),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard')),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await launchUrl(Uri.parse(info.apkUrl), mode: LaunchMode.externalApplication);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir le navigateur.')));
            }
          },
          child: const Text('Télécharger'),
        ),
      ],
    );
  }
}
