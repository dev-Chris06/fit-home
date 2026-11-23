// Les notifications de rappel, programmées sur le téléphone (aucune connexion nécessaire).
// Les dates viennent de data/reminders.dart ; ici on ne fait que les confier à Android.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../app_state.dart';
import '../data/reminders.dart';

class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'rappels',
      'Rappels de séance',
      channelDescription: 'Te rappelle de faire ta séance',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  /// À appeler une fois au démarrage. Sans effet (et sans erreur) là où les notifications n'existent pas, comme les tests.
  static Future<void> init() async {
    try {
      await _plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Demande l'autorisation d'afficher des notifications (Android 13 et plus). true si elle est accordée.
  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enabled() async {
    if (!_ready) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Efface les rappels prévus et reprogramme ceux qui correspondent aux réglages et au journal.
  static Future<void> reschedule() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAllPendingNotifications();
      final s = app.reminders;
      final last = app.sortedEntries.isEmpty ? null : DateTime.tryParse(app.sortedEntries.first.date);
      final slots = reminderSlots(s, now: DateTime.now(), lastSession: last);
      for (var i = 0; i < slots.length; i++) {
        final text = reminderText(s, slots[i], app.nextSession);
        await _plugin.zonedSchedule(
          id: 100 + i,
          // L'heure locale du téléphone est convertie en instant UTC : pas besoin de connaître le fuseau.
          scheduledDate: tz.TZDateTime.from(slots[i].when, tz.UTC),
          notificationDetails: _details,
          // « Inexact » : Android peut décaler de quelques minutes pour économiser la batterie,
          // mais aucune permission d'alarme exacte n'est demandée.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: text.title,
          body: text.body,
        );
      }
    } catch (_) {
      // Un rappel qui n'a pas pu être programmé ne doit jamais bloquer l'app.
    }
  }

  /// Envoie tout de suite une notification d'essai.
  static Future<void> test() async {
    if (!_ready) return;
    try {
      await _plugin.show(id: 1, title: 'Rappel d’essai', body: 'Les rappels de Fit Home fonctionnent sur ce téléphone.', notificationDetails: _details);
    } catch (_) {}
  }
}
