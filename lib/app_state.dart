// L'état de l'app : le journal des séances, le palier et les réglages.
// Tout est enregistré sur le téléphone avec shared_preferences (un petit stockage clé → valeur).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/programme.dart';

class JournalEntry {
  final String id;
  final String date; // AAAA-MM-JJ
  final String type; // 'A', 'B', 'C' ou 'P'
  final String charge;
  final String ressenti; // 'facile', 'correct' ou 'dur'
  final bool reussi;
  final String notes;
  final int palier;
  final String createdAt;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.type,
    this.charge = '',
    this.ressenti = 'correct',
    this.reussi = false,
    this.notes = '',
    this.palier = 1,
    required this.createdAt,
  });

  JournalEntry copyWith({String? charge, String? ressenti, bool? reussi, String? notes}) => JournalEntry(
        id: id,
        date: date,
        type: type,
        charge: charge ?? this.charge,
        ressenti: ressenti ?? this.ressenti,
        reussi: reussi ?? this.reussi,
        notes: notes ?? this.notes,
        palier: palier,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'type': type,
        'charge': charge,
        'ressenti': ressenti,
        'reussi': reussi,
        'notes': notes,
        'palier': palier,
        'createdAt': createdAt,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String? ?? '',
        date: j['date'] as String? ?? '',
        type: j['type'] as String? ?? 'A',
        charge: j['charge'] as String? ?? '',
        ressenti: j['ressenti'] as String? ?? 'correct',
        reussi: j['reussi'] as bool? ?? false,
        notes: j['notes'] as String? ?? '',
        palier: (j['palier'] as num?)?.toInt() ?? 1,
        createdAt: j['createdAt'] as String? ?? '',
      );
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Fonctions pures sur le journal (testées sans téléphone).
class JournalLogic {
  /// Du plus récent au plus ancien.
  static List<JournalEntry> sorted(List<JournalEntry> e) =>
      [...e]..sort((a, b) => (b.date + b.createdAt).compareTo(a.date + a.createdAt));

  /// Prochaine séance de la rotation A → B → C, d'après la dernière séance A, B ou C notée.
  static String nextSession(List<JournalEntry> e) {
    for (final x in sorted(e)) {
      final n = nextInRotation[x.type];
      if (n != null) return n;
    }
    return 'A';
  }

  static int doneCount(List<JournalEntry> e, String type) => e.where((x) => x.type == type).length;

  static int last7Days(List<JournalEntry> e, DateTime now) {
    final from = isoDate(now.subtract(const Duration(days: 6)));
    final to = isoDate(now);
    return e.where((x) => x.date.compareTo(from) >= 0 && x.date.compareTo(to) <= 0).length;
  }

  /// Conseil de palier : 'up' si les 3 dernières séances A/B/C sont réussies et pas dures,
  /// 'down' si les 2 dernières sont dures et ratées, sinon null.
  static String? palierAdvice(List<JournalEntry> e, int palier) {
    final main = sorted(e).where((x) => nextInRotation.containsKey(x.type)).toList();
    if (palier < 3 && main.length >= 3 && main.take(3).every((x) => x.reussi && x.ressenti != 'dur')) return 'up';
    if (main.length >= 2 && main.take(2).every((x) => x.ressenti == 'dur' && !x.reussi)) return 'down';
    return null;
  }
}

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;
  List<JournalEntry> entries = [];
  int palier = 1;
  bool autoUpdateCheck = true;
  String lastUpdateCheck = '';

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final raw = p.getString('journal');
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        entries = list.map((x) => JournalEntry.fromJson(Map<String, dynamic>.from(x as Map))).toList();
      }
      palier = (p.getInt('palier') ?? 1).clamp(1, 3);
      autoUpdateCheck = p.getBool('autoUpdateCheck') ?? true;
      lastUpdateCheck = p.getString('lastUpdateCheck') ?? '';
    } catch (_) {
      // Stockage illisible : on repart d'un journal vide plutôt que de bloquer l'app.
    }
    notifyListeners();
  }

  Future<void> _saveEntries() async {
    await _prefs?.setString('journal', jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  List<JournalEntry> get sortedEntries => JournalLogic.sorted(entries);
  String get nextSession => JournalLogic.nextSession(entries);
  int doneCount(String type) => JournalLogic.doneCount(entries, type);
  int get last7Days => JournalLogic.last7Days(entries, DateTime.now());
  String? get palierAdvice => JournalLogic.palierAdvice(entries, palier);

  Future<void> addEntry(JournalEntry e) async {
    entries = [...entries, e];
    notifyListeners();
    await _saveEntries();
  }

  /// Remplace une séance déjà notée (même id) : sert aux réponses rapides de fin de séance.
  Future<void> updateEntry(JournalEntry e) async {
    entries = [for (final x in entries) x.id == e.id ? e : x];
    notifyListeners();
    await _saveEntries();
  }

  Future<void> deleteEntry(String id) async {
    entries = entries.where((e) => e.id != id).toList();
    notifyListeners();
    await _saveEntries();
  }

  Future<void> setPalier(int p) async {
    palier = p.clamp(1, 3);
    notifyListeners();
    await _prefs?.setInt('palier', palier);
  }

  Future<void> setAutoUpdateCheck(bool v) async {
    autoUpdateCheck = v;
    notifyListeners();
    await _prefs?.setBool('autoUpdateCheck', v);
  }

  Future<void> markUpdateChecked() async {
    lastUpdateCheck = isoDate(DateTime.now());
    await _prefs?.setString('lastUpdateCheck', lastUpdateCheck);
  }
}

/// Une seule instance pour toute l'app (simple et suffisant ici).
final app = AppState();
