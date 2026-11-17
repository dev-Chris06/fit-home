import 'package:fit_home/app_state.dart';
import 'package:fit_home/data/programme.dart';
import 'package:fit_home/data/session_plan.dart';
import 'package:fit_home/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

JournalEntry e(String date, String type, {bool ok = true, String r = 'correct'}) =>
    JournalEntry(id: '$date$type', date: date, type: type, reussi: ok, ressenti: r, createdAt: date);

void main() {
  group('rotation', () {
    test('sans séance : A', () => expect(JournalLogic.nextSession([]), 'A'));
    test('après A : B, après C : A', () {
      expect(JournalLogic.nextSession([e('2026-11-01', 'A')]), 'B');
      expect(JournalLogic.nextSession([e('2026-11-01', 'A'), e('2026-11-03', 'B'), e('2026-11-05', 'C')]), 'A');
    });
    test('la posture ne compte pas dans la rotation', () {
      expect(JournalLogic.nextSession([e('2026-11-01', 'A'), e('2026-11-02', 'P')]), 'B');
    });
  });

  group('paliers', () {
    test('3 séances réussies : monter', () {
      final l = [e('2026-11-01', 'A'), e('2026-11-03', 'B'), e('2026-11-05', 'C')];
      expect(JournalLogic.palierAdvice(l, 1), 'up');
      expect(JournalLogic.palierAdvice(l, 3), isNull);
    });
    test('2 séances dures et ratées : alléger', () {
      final l = [e('2026-11-01', 'A', ok: false, r: 'dur'), e('2026-11-03', 'B', ok: false, r: 'dur')];
      expect(JournalLogic.palierAdvice(l, 1), 'down');
    });
  });

  group('plan de séance', () {
    test('séance A palier 1 : échauffement + 7 exercices × 3 séries, repos 60 s', () {
      final steps = buildPlan(sessionA, palier: 1, doneCount: 0);
      final work = steps.where((s) => s.kind == StepKind.work).toList();
      expect(work.length, 3 + 7 * 3);
      expect(steps.last.kind, StepKind.work);
      expect(steps.firstWhere((s) => s.kind == StepKind.rest && s.phase == 'Séance A').seconds, 60);
    });
    test('palier 3 : pompes classiques et repos 40 s', () {
      final steps = buildPlan(sessionA, palier: 3, doneCount: 0, withWarmup: false);
      expect(steps.any((s) => s.exerciseId == 'classiques'), isTrue);
      expect(steps.any((s) => s.exerciseId == 'pompes'), isFalse);
      expect(steps.firstWhere((s) => s.kind == StepKind.rest).seconds, 40);
    });
    test('alternances une fois sur deux', () {
      expect(buildPlan(sessionA, palier: 1, doneCount: 1).any((s) => s.exerciseId == 'marteau'), isTrue);
      expect(buildPlan(sessionB, palier: 1, doneCount: 1).any((s) => s.exerciseId == 'chaise'), isTrue);
      expect(buildPlan(sessionB, palier: 1, doneCount: 2).any((s) => s.exerciseId == 'fentes'), isTrue);
    });
    test('circuit : 3 tours au palier 1, 4 au palier 3', () {
      int work(int p) => buildPlan(sessionC, palier: p, doneCount: 0, withWarmup: false).where((s) => s.kind == StepKind.work).length;
      expect(work(1), 21);
      expect(work(3), 28);
    });
  });

  group('séries et exercice suivant', () {
    test('chaque effort connaît sa série', () {
      final steps = buildPlan(sessionA, palier: 1, doneCount: 0, withWarmup: false);
      final squat = steps.where((s) => s.kind == StepKind.work && s.exerciseId == 'squat').toList();
      expect(squat.map((s) => '${s.set}/${s.sets}').toList(), ['1/3', '2/3', '3/3']);
      // le repos après la série 1 annonce la série 2 du même exercice
      expect(steps[1].kind, StepKind.rest);
      expect('${steps[1].set}/${steps[1].sets}', '2/3');
      expect(steps[2].item, steps[0].item);
    });
    test('« Exercice suivant » saute les séries restantes', () {
      final steps = buildPlan(sessionA, palier: 1, doneCount: 0, withWarmup: false);
      final j = nextExerciseIndex(steps, 0); // depuis la série 1 du squat
      expect(steps[j].exerciseId, 'pompes');
      expect(steps[j].set, 1);
      expect(nextExerciseIndex(steps, 1), j); // depuis le repos entre deux séries
      expect(nextExerciseIndex(steps, steps.length - 1), steps.length); // dernier exercice : fin de séance
    });
  });

  group('versions', () {
    test('comparaison', () {
      expect(isNewer('1.0.10', '1.0.9'), isTrue);
      expect(isNewer('v1.1.0', '1.0.9'), isTrue);
      expect(isNewer('1.0.0', '1.0.0'), isFalse);
      expect(isNewer('1.0.0', '1.2.0'), isFalse);
    });
  });
}
