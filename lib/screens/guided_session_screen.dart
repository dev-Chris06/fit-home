// La séance guidée : l'app enchaîne échauffement, séries et repos avec un minuteur.
// L'écran reste allumé pendant la séance (wakelock) et le téléphone vibre à la fin de chaque minuteur.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../anim/exercise_view.dart';
import '../app_state.dart';
import '../data/programme.dart';
import '../data/session_plan.dart';
import '../theme.dart';
import 'log_form_screen.dart';

class GuidedSessionScreen extends StatefulWidget {
  final SessionDef session;
  const GuidedSessionScreen({super.key, required this.session});
  @override
  State<GuidedSessionScreen> createState() => _GuidedSessionScreenState();
}

class _GuidedSessionScreenState extends State<GuidedSessionScreen> {
  late final List<PlanStep> steps;
  int index = 0;
  DateTime? endAt; // fin du minuteur en cours (null = étape « Terminé » manuelle)
  int pausedMs = 0; // temps restant mémorisé pendant une pause
  bool paused = false;
  Timer? timer;
  int lastWholeSecond = -1;
  final started = DateTime.now();

  @override
  void initState() {
    super.initState();
    steps = buildPlan(widget.session, palier: app.palier, doneCount: app.doneCount(widget.session.id));
    WakelockPlus.enable().catchError((_) {});
    _enter(0);
    timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  @override
  void dispose() {
    timer?.cancel();
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  bool get finished => index >= steps.length;
  PlanStep get step => steps[index];

  void _enter(int i) {
    index = i;
    paused = false;
    lastWholeSecond = -1;
    if (!finished && step.seconds != null) {
      endAt = DateTime.now().add(Duration(seconds: step.seconds!));
    } else {
      endAt = null;
    }
    setState(() {});
  }

  int get remainingMs {
    if (paused) return pausedMs;
    if (endAt == null) return 0;
    return endAt!.difference(DateTime.now()).inMilliseconds;
  }

  void _tick() {
    if (finished || paused || endAt == null) return;
    final ms = remainingMs;
    if (ms <= 0) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);
      _next();
      return;
    }
    final whole = (ms / 1000).ceil();
    if (whole != lastWholeSecond) {
      if (whole <= 3) HapticFeedback.selectionClick();
      lastWholeSecond = whole;
      setState(() {});
    }
  }

  void _next() => _enter(index + 1);
  void _prev() => _enter(index > 0 ? index - 1 : 0);

  void _togglePause() {
    if (endAt == null) return;
    setState(() {
      if (paused) {
        endAt = DateTime.now().add(Duration(milliseconds: pausedMs));
        paused = false;
      } else {
        pausedMs = remainingMs;
        paused = true;
      }
    });
  }

  void _addTime(int s) {
    if (endAt == null) return;
    setState(() {
      if (paused) {
        pausedMs += s * 1000;
      } else {
        endAt = endAt!.add(Duration(seconds: s));
      }
    });
  }

  Future<void> _confirmQuit() async {
    if (finished) {
      Navigator.pop(context);
      return;
    }
    final quit = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Palette.surface,
        title: const Text('Arrêter la séance ?'),
        content: const Text('Ta progression dans cette séance ne sera pas gardée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Continuer')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Arrêter')),
        ],
      ),
    );
    if (quit == true && mounted) Navigator.pop(context);
  }

  String _clock(int ms) {
    final s = (ms / 1000).ceil().clamp(0, 5999);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        body: SafeArea(child: finished ? _finishedView() : _stepView()),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.close), tooltip: 'Arrêter', onPressed: _confirmQuit),
          Expanded(child: Eyebrow(step.phase, color: Palette.main)),
          Text('${index + 1} / ${steps.length}', style: const TextStyle(color: Palette.muted)),
        ]),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: LinearProgressIndicator(
            value: (index + 1) / steps.length,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: Palette.surface,
            color: Palette.main,
          ),
        ),
      ]),
    );
  }

  Widget _stepView() {
    final s = step;
    final ex = s.exerciseId == null ? null : exercises[s.exerciseId];
    final isRest = s.kind == StepKind.rest;
    final timed = endAt != null || paused;
    return Column(children: [
      _topBar(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          children: isRest ? _restBody(s, ex) : _workBody(s, ex),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(children: [
          if (!timed && !isRest)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(icon: const Icon(Icons.check), label: const Text('Série terminée'), onPressed: _next),
            ),
          if (timed)
            Row(children: [
              if (isRest) ...[
                Expanded(child: OutlinedButton(onPressed: () => _addTime(15), child: const Text('+15 s'))),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                  label: Text(paused ? 'Reprendre' : 'Pause'),
                  onPressed: _togglePause,
                ),
              ),
            ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton.icon(onPressed: index > 0 ? _prev : null, icon: const Icon(Icons.skip_previous), label: const Text('Précédent')),
            TextButton.icon(onPressed: _next, icon: const Icon(Icons.skip_next), label: Text(isRest ? 'Passer le repos' : 'Passer')),
          ]),
        ]),
      ),
    ]);
  }

  List<Widget> _workBody(PlanStep s, Exercise? ex) {
    return [
      if (ex != null) AspectRatio(aspectRatio: 1.15, child: ExerciseView(ex.id, playing: !paused)),
      const SizedBox(height: 12),
      if (ex != null) Eyebrow(ex.zone),
      Text(s.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
      Text(s.detail, style: const TextStyle(fontSize: 18, color: Palette.main, fontWeight: FontWeight.w700)),
      if (endAt != null || paused)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_clock(remainingMs), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
        ),
      if (ex != null) ...[
        const SizedBox(height: 6),
        Text(ex.tip, style: const TextStyle(color: Palette.muted, height: 1.35)),
      ],
    ];
  }

  List<Widget> _restBody(PlanStep s, Exercise? next) {
    final total = (s.seconds ?? 1) * 1000;
    final ratio = (remainingMs / total).clamp(0.0, 1.0);
    return [
      const SizedBox(height: 8),
      Center(child: Text(s.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
      Center(child: Text(s.detail, style: const TextStyle(color: Palette.muted))),
      const SizedBox(height: 20),
      Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(value: ratio, strokeWidth: 12, backgroundColor: Palette.surface, color: Palette.main),
            Center(
              child: Text(_clock(remainingMs), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      if (next != null)
        Panel(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            SizedBox(width: 90, height: 90, child: ExerciseView(next.id, playing: !paused, radius: const BorderRadius.all(Radius.circular(12)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('Ensuite', color: Palette.muted),
                Text(next.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(next.zone, style: const TextStyle(color: Palette.accent, fontSize: 13)),
              ]),
            ),
          ]),
        ),
    ];
  }

  Widget _finishedView() {
    final minutes = DateTime.now().difference(started).inMinutes;
    final loggable = ['A', 'B', 'C', 'P'].contains(widget.session.id);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 64, color: Palette.main),
          const SizedBox(height: 12),
          Text('${widget.session.title} terminée', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('$minutes min · pense à 5 minutes d’étirements', textAlign: TextAlign.center, style: const TextStyle(color: Palette.muted)),
          const SizedBox(height: 28),
          if (loggable)
            FilledButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Noter la séance'),
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LogFormScreen(initialType: widget.session.id))),
            ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
