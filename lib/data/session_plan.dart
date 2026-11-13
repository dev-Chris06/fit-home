// Transforme une séance (liste d'exercices) en suite d'étapes pour la séance guidée :
// effort, repos, effort, repos… C'est de la logique pure, testée dans test/session_plan_test.dart.
import 'programme.dart';

enum StepKind { work, rest }

class PlanStep {
  final StepKind kind;
  final String? exerciseId; // pour un repos : l'exercice qui suit (affiché en « Ensuite »)
  final String title; // « Squat goblet » ou « Repos »
  final String detail; // « Série 2/3 · 10 à 15 répétitions »
  final int? seconds; // null = l'utilisateur appuie sur « Terminé »
  final String phase; // « Échauffement », « Tour 2/3 »…
  const PlanStep(this.kind, this.exerciseId, this.title, this.detail, this.seconds, this.phase);
}

/// Les exercices réellement faits pour une séance, après les alternances et le palier.
/// [doneCount] = nombre de fois où cette séance a déjà été faite (sert aux alternances une fois sur deux).
List<SessionItem> effectiveItems(SessionDef s, {required int palier, required int doneCount}) {
  final odd = doneCount.isOdd;
  return s.items.map((it) {
    if (s.id == 'A' && it.exerciseId == 'pompes' && palier >= 3) {
      return SessionItem('classiques', sets: it.sets, reps: '8 à 12 répétitions');
    }
    if (s.id == 'A' && it.exerciseId == 'curl' && odd) {
      return SessionItem('marteau', sets: it.sets, reps: it.reps);
    }
    if (s.id == 'B' && it.exerciseId == 'fentes' && odd) {
      return const SessionItem('chaise', reps: '30 à 45 s', seconds: 40);
    }
    return it;
  }).toList();
}

List<PlanStep> buildPlan(SessionDef s, {required int palier, required int doneCount, bool withWarmup = true}) {
  final steps = <PlanStep>[];
  final rest = restSeconds(palier);

  void addWarmup() {
    for (final it in warmup.items) {
      steps.add(PlanStep(StepKind.work, it.exerciseId, it.exercise.name, it.reps, it.seconds, 'Échauffement'));
    }
  }

  if (withWarmup && (s.kind == SessionKind.muscu || s.kind == SessionKind.circuit)) addWarmup();

  if (s.kind == SessionKind.circuit) {
    final rounds = circuitRounds(palier);
    final items = s.items;
    for (var r = 1; r <= rounds; r++) {
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        steps.add(PlanStep(StepKind.work, it.exerciseId, it.exercise.name, 'Effort · ${it.seconds ?? 40} s', it.seconds ?? 40, 'Tour $r/$rounds'));
        final lastOfRound = i == items.length - 1;
        final lastOfAll = lastOfRound && r == rounds;
        if (!lastOfAll) {
          final next = lastOfRound ? items.first : items[i + 1];
          steps.add(PlanStep(StepKind.rest, next.exerciseId, lastOfRound ? 'Fin du tour' : 'Repos', lastOfRound ? 'Respire, bois un peu d’eau' : 'Prépare-toi',
              lastOfRound ? 60 : 20, 'Tour $r/$rounds'));
        }
      }
    }
    return steps;
  }

  final items = s.kind == SessionKind.muscu ? effectiveItems(s, palier: palier, doneCount: doneCount) : s.items;
  final restBetween = s.kind == SessionKind.posture || s.kind == SessionKind.warmup ? 10 : rest;
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    for (var set = 1; set <= it.sets; set++) {
      final setLabel = it.sets > 1 ? 'Série $set/${it.sets} · ' : '';
      steps.add(PlanStep(StepKind.work, it.exerciseId, it.exercise.name, '$setLabel${it.reps}', it.seconds, s.title));
      final lastSet = set == it.sets;
      final lastItem = i == items.length - 1;
      if (!(lastSet && lastItem)) {
        final nextId = lastSet ? items[i + 1].exerciseId : it.exerciseId;
        steps.add(PlanStep(StepKind.rest, nextId, 'Repos', lastSet ? 'Exercice suivant' : 'Série suivante', restBetween, s.title));
      }
    }
  }
  return steps;
}

/// Durée estimée d'une séance en minutes (les séries « Terminé » comptent 40 s).
int estimatedMinutes(List<PlanStep> steps) {
  final secs = steps.fold<int>(0, (a, st) => a + (st.seconds ?? 40));
  return (secs / 60).round();
}
