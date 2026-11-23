// Le réglage des rappels : proposé au premier lancement, puis modifiable à tout moment depuis Plus → Rappels.
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../data/reminders.dart';
import '../services/reminder_service.dart';
import '../theme.dart';

class ReminderScreen extends StatefulWidget {
  /// true au premier lancement : texte d'accueil et bouton « Continuer ».
  final bool firstTime;
  const ReminderScreen({super.key, this.firstTime = false});
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late ReminderSettings s = app.reminders;
  bool saving = false;

  Widget _mode(ReminderMode m, IconData icon, String title, String sub) {
    final selected = s.mode == m;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? Palette.main.withValues(alpha: .14) : Palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? Palette.main : Palette.line, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => s = s.copyWith(mode: m)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(icon, color: selected ? Palette.main : Palette.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(sub, style: const TextStyle(color: Palette.muted, fontSize: 13)),
                ]),
              ),
              if (selected) const Icon(Icons.check_circle, color: Palette.main),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
      helpText: 'Heure du rappel',
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t != null) setState(() => s = s.copyWith(hour: t.hour, minute: t.minute));
  }

  Future<void> _save() async {
    setState(() => saving = true);
    var granted = true;
    if (s.mode != ReminderMode.off) granted = await Reminders.requestPermission() || await Reminders.enabled();
    await app.setReminders(s);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      duration: Duration(seconds: granted ? 3 : 8),
      content: Text(s.mode == ReminderMode.off
          ? 'Rappels désactivés.'
          : granted
              ? 'Rappels enregistrés : ${s.summary.toLowerCase()}.'
              : 'Réglage enregistré, mais les notifications sont bloquées. Active-les dans les réglages du téléphone : Applications, puis Fit Home, puis Notifications.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fixeEmpty = s.mode == ReminderMode.fixe && s.weekdays.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Rappels'), automaticallyImplyLeading: !widget.firstTime),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            widget.firstTime
                ? 'Choisis comment Fit Home te rappelle de t’entraîner. Tu pourras changer ce réglage à tout moment dans l’onglet Plus, rubrique Rappels.'
                : 'Les rappels arrivent même sans internet.',
            style: const TextStyle(color: Palette.muted),
          ),
          const SizedBox(height: 16),
          _mode(ReminderMode.relance, Icons.notifications_active_outlined, 'Me relancer si je ne m’entraîne pas',
              'Une notification seulement après quelques jours sans séance'),
          _mode(ReminderMode.fixe, Icons.event_repeat, 'Certains jours, à heure fixe', 'Par exemple lundi, mercredi et vendredi'),
          _mode(ReminderMode.off, Icons.notifications_off_outlined, 'Pas de rappel', 'Tu peux les activer plus tard'),
          if (s.mode == ReminderMode.relance) ...[
            const SizedBox(height: 12),
            const Eyebrow('Après combien de jours sans séance ?', color: Palette.muted),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final d in const [2, 3, 4, 5])
                ChoiceChip(label: Text('$d jours'), selected: s.days == d, showCheckmark: false, onSelected: (_) => setState(() => s = s.copyWith(days: d))),
            ]),
          ],
          if (s.mode == ReminderMode.fixe) ...[
            const SizedBox(height: 12),
            const Eyebrow('Quels jours ?', color: Palette.muted),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(dayShort[d - 1]),
                  selected: s.weekdays.contains(d),
                  showCheckmark: false,
                  onSelected: (on) => setState(() => s = s.copyWith(weekdays: on ? {...s.weekdays, d} : ({...s.weekdays}..remove(d)))),
                ),
            ]),
            if (fixeEmpty) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Choisis au moins un jour.', style: TextStyle(color: Palette.accent))),
          ],
          if (s.mode != ReminderMode.off) ...[
            const SizedBox(height: 16),
            const Eyebrow('À quelle heure ?', color: Palette.muted),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(icon: const Icon(Icons.schedule), label: Text(s.time, style: const TextStyle(fontSize: 18)), onPressed: _pickTime),
            ),
            const SizedBox(height: 16),
            const Panel(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.battery_alert_outlined, color: Palette.accent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sur certains téléphones (Tecno, Infinix, Itel, Xiaomi…), l’économie de batterie peut bloquer les rappels. '
                    'Si tu n’en reçois pas, autorise Fit Home à fonctionner en arrière-plan dans les réglages de la batterie.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ]),
            ),
            if (!widget.firstTime)
              TextButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: const Text('Envoyer un rappel d’essai'),
                onPressed: () async {
                  final ok = await Reminders.requestPermission() || await Reminders.enabled();
                  await Reminders.test();
                  if (!context.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les notifications sont bloquées pour Fit Home dans les réglages du téléphone.')));
                  }
                },
              ),
          ],
        ],
      ),
      // Le bouton reste toujours visible en bas de l'écran.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: saving || fixeEmpty ? null : _save,
            child: Text(widget.firstTime ? 'Continuer' : 'Enregistrer'),
          ),
        ),
      ),
    );
  }
}
