// Les rappels : réglages et calcul des dates (fonctions pures, testées sans téléphone).
// L'envoi des notifications est dans services/reminder_service.dart.

enum ReminderMode { relance, fixe, off }

class ReminderSettings {
  final ReminderMode mode;
  /// Relance : nombre de jours sans séance avant le rappel (2 à 5).
  final int days;
  final int hour, minute;
  /// Jours fixes : 1 = lundi … 7 = dimanche.
  final Set<int> weekdays;

  const ReminderSettings({
    this.mode = ReminderMode.relance,
    this.days = 3,
    this.hour = 18,
    this.minute = 0,
    this.weekdays = const {1, 3, 5},
  });

  ReminderSettings copyWith({ReminderMode? mode, int? days, int? hour, int? minute, Set<int>? weekdays}) => ReminderSettings(
        mode: mode ?? this.mode,
        days: days ?? this.days,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        weekdays: weekdays ?? this.weekdays,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'days': days,
        'hour': hour,
        'minute': minute,
        'weekdays': (weekdays.toList()..sort()),
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
        mode: ReminderMode.values.firstWhere((m) => m.name == j['mode'], orElse: () => ReminderMode.relance),
        days: ((j['days'] as num?)?.toInt() ?? 3).clamp(2, 5),
        hour: ((j['hour'] as num?)?.toInt() ?? 18).clamp(0, 23),
        minute: ((j['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
        weekdays: {for (final d in (j['weekdays'] as List<dynamic>? ?? const [1, 3, 5])) (d as num).toInt()}..removeWhere((d) => d < 1 || d > 7),
      );

  String get time => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Résumé affiché dans l'onglet Plus.
  String get summary => switch (mode) {
        ReminderMode.relance => 'Après $days jours sans séance, à $time',
        ReminderMode.fixe => weekdays.isEmpty ? 'Aucun jour choisi' : '${dayNames(weekdays)} à $time',
        ReminderMode.off => 'Désactivés',
      };
}

const dayShort = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

String dayNames(Set<int> days) => (days.toList()..sort()).map((d) => dayShort[d - 1]).join(', ');

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Un rappel à programmer : quand, et combien de jours se seront écoulés depuis la dernière séance (null s'il n'y en a pas).
class ReminderSlot {
  final DateTime when;
  final int? daysSince;
  const ReminderSlot(this.when, this.daysSince);
}

/// Les prochains rappels à programmer.
/// Relance : le jour « dernière séance + N jours » à l'heure choisie (ou la prochaine occurrence de cette heure si
/// elle est déjà passée), puis deux relances 2 et 4 jours plus tard. Tout est recalculé à chaque séance notée.
/// Jours fixes : chaque jour choisi des 4 prochaines semaines, sauf un jour où une séance est déjà notée.
List<ReminderSlot> reminderSlots(ReminderSettings s, {required DateTime now, DateTime? lastSession, int horizonDays = 28}) {
  DateTime at(DateTime day) => DateTime(day.year, day.month, day.day, s.hour, s.minute);
  int? since(DateTime t) => lastSession == null ? null : _day(t).difference(_day(lastSession)).inDays;

  switch (s.mode) {
    case ReminderMode.off:
      return const [];
    case ReminderMode.relance:
      final base = _day(lastSession ?? now);
      var first = at(base.add(Duration(days: s.days)));
      if (!first.isAfter(now)) {
        first = at(_day(now));
        if (!first.isAfter(now)) first = at(_day(now).add(const Duration(days: 1)));
      }
      return [
        for (final extra in const [0, 2, 4])
          () {
            final t = at(_day(first).add(Duration(days: extra)));
            return ReminderSlot(t, since(t));
          }(),
      ];
    case ReminderMode.fixe:
      final out = <ReminderSlot>[];
      for (var i = 0; i <= horizonDays; i++) {
        final d = _day(now).add(Duration(days: i));
        if (!s.weekdays.contains(d.weekday)) continue;
        if (lastSession != null && _day(lastSession) == d) continue;
        final t = at(d);
        if (t.isAfter(now)) out.add(ReminderSlot(t, since(t)));
      }
      return out;
  }
}

/// Le texte d'une notification.
({String title, String body}) reminderText(ReminderSettings s, ReminderSlot slot, String nextSession) {
  final seance = 'la séance $nextSession';
  if (s.mode == ReminderMode.fixe) {
    return (title: 'C’est l’heure du sport', body: 'Au programme : $seance. Échauffement compris, 30 à 40 minutes.');
  }
  final n = slot.daysSince;
  return (
    title: n == null ? 'Ta première séance t’attend' : 'Déjà $n jours sans séance',
    body: 'Au programme : $seance. Même une séance courte compte.',
  );
}
