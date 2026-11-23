// Le formulaire pour noter une séance dans le journal.
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LogFormScreen extends StatefulWidget {
  final String? initialType;
  const LogFormScreen({super.key, this.initialType});
  @override
  State<LogFormScreen> createState() => _LogFormScreenState();
}

class _LogFormScreenState extends State<LogFormScreen> {
  late String type = widget.initialType ?? app.nextSession;
  DateTime date = DateTime.now();
  String ressenti = 'correct';
  bool reussi = false;
  final charge = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    charge.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(now.year - 2), lastDate: now);
    if (d != null) setState(() => date = d);
  }

  Future<void> _save() async {
    final now = DateTime.now();
    await app.addEntry(JournalEntry(
      id: now.microsecondsSinceEpoch.toString(),
      date: isoDate(date),
      type: type,
      charge: charge.text.trim(),
      ressenti: ressenti,
      reussi: reussi,
      notes: notes.text.trim(),
      palier: app.palier,
      createdAt: now.toIso8601String(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${sessionLabel(type)} enregistrée.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noter une séance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Eyebrow('Séance', color: Palette.muted),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'A', label: Text('A')),
              ButtonSegment(value: 'B', label: Text('B')),
              ButtonSegment(value: 'C', label: Text('C')),
              ButtonSegment(value: 'P', label: Text('Posture')),
            ],
            selected: {type},
            onSelectionChanged: (s) => setState(() => type = s.first),
          ),
          const SizedBox(height: 18),
          const Eyebrow('Date', color: Palette.muted),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(frDate(isoDate(date))),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: charge,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Charge utilisée', hintText: 'Ex. 2 bouteilles de 1,5 L'),
          ),
          const SizedBox(height: 8),
          const Eyebrow('Ressenti', color: Palette.muted),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final r in const ['facile', 'correct', 'dur'])
              ChoiceChip(
                label: Text(r[0].toUpperCase() + r.substring(1)),
                selected: ressenti == r,
                onSelected: (_) => setState(() => ressenti = r),
              ),
          ]),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: reussi,
            onChanged: (v) => setState(() => reussi = v ?? false),
            title: const Text('Toutes les séries réussies proprement'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notes,
            maxLines: 3,
            maxLength: 400,
            decoration: const InputDecoration(labelText: 'Notes', hintText: 'Ex. pompes : 10, 9, 8 · genou gauche un peu raide'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Enregistrer la séance')),
        ],
      ),
    );
  }
}
