// Recherche de mise à jour : l'app demande à GitHub quelle est la dernière version publiée
// (la « release » la plus récente du dépôt) et la compare à la sienne.
// Le seul appel réseau de toute l'app ; sans internet, elle affiche simplement un message.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const String repoOwner = 'dev-Chris06';
const String repoName = 'fit-home';
const String apkName = 'fit-home.apk';

/// Lien permanent vers l'APK de la dernière version.
const String latestApkUrl = 'https://github.com/$repoOwner/$repoName/releases/latest/download/$apkName';
const String releasesPageUrl = 'https://github.com/$repoOwner/$repoName/releases';

class UpdateInfo {
  final String current; // version installée, ex. 1.0.2
  final String latest; // dernière version publiée, ex. 1.0.3
  final String notes; // ce qui a changé
  final String apkUrl;
  final bool available;
  const UpdateInfo(this.current, this.latest, this.notes, this.apkUrl, this.available);
}

/// « v1.2.10 » → [1, 2, 10]
List<int> _parts(String v) {
  final clean = v.trim().replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
  return clean.split('.').map((x) => int.tryParse(x.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
}

/// Vrai si [candidate] est plus récente que [current].
bool isNewer(String candidate, String current) {
  final a = _parts(candidate), b = _parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);
  @override
  String toString() => message;
}

Future<UpdateInfo> checkForUpdate() async {
  final info = await PackageInfo.fromPlatform();
  final current = info.version;
  http.Response res;
  try {
    res = await http.get(
      Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest'),
      headers: {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 12));
  } catch (_) {
    throw const UpdateException('Pas de connexion internet. Réessaie quand tu as du réseau.');
  }
  if (res.statusCode == 404) {
    return UpdateInfo(current, current, '', latestApkUrl, false);
  }
  if (res.statusCode != 200) {
    throw UpdateException('GitHub ne répond pas pour le moment (code ${res.statusCode}). Réessaie plus tard.');
  }
  final j = jsonDecode(res.body) as Map<String, dynamic>;
  final tag = (j['tag_name'] as String?) ?? current;
  final notes = (j['body'] as String?) ?? '';
  var url = latestApkUrl;
  for (final a in (j['assets'] as List<dynamic>? ?? const [])) {
    final m = a as Map<String, dynamic>;
    if ((m['name'] as String?)?.endsWith('.apk') ?? false) {
      url = (m['browser_download_url'] as String?) ?? url;
      break;
    }
  }
  final latest = tag.replaceFirst(RegExp(r'^[vV]'), '');
  return UpdateInfo(current, latest, notes.trim(), url, isNewer(latest, current));
}
