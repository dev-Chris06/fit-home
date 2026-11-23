import 'package:fit_home/app_state.dart';
import 'package:fit_home/data/programme.dart';
import 'package:fit_home/data/reminders.dart';
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

  group('remplacements', () {
    test('un exercice remplacé garde ses séries et prend ses répétitions', () {
      final items = effectiveItems(sessionA, palier: 1, doneCount: 0, subs: {'squat': 'sumo'});
      expect(items.first.exerciseId, 'sumo');
      expect(items.first.sets, 3);
      expect(items.first.reps, exercises['sumo']!.reps);
    });
    test('un maintien remplaçant devient chronométré', () {
      final items = effectiveItems(sessionB, palier: 1, doneCount: 0, subs: {'crunchs': 'creux'});
      expect(items.firstWhere((i) => i.exerciseId == 'creux').seconds, 20);
    });
    test('en circuit, la durée d’effort reste 40 s', () {
      final items = effectiveItems(sessionC, palier: 1, doneCount: 0, subs: {'jump': 'burpees', 'releves': 'creux'});
      expect(items.first.exerciseId, 'burpees');
      expect(items.map((i) => i.seconds).toSet(), {40});
    });
    test('le remplacement passe avant les alternances', () {
      final items = effectiveItems(sessionA, palier: 3, doneCount: 1, subs: {'pompes': 'pompes_declinees'});
      expect(items.any((i) => i.exerciseId == 'pompes_declinees'), isTrue);
      expect(items.any((i) => i.exerciseId == 'marteau'), isTrue);
    });
    test('chaque exercice a une famille connue et un palier de 1 à 3', () {
      for (final e in exercises.values) {
        expect(Groups.all.contains(e.group), isTrue, reason: e.id);
        expect(e.level, inInclusiveRange(1, 3), reason: e.id);
      }
      expect(exercises.length, 52);
    });
  });

  group('rappels', () {
    // Lundi 23 novembre 2026, 10 h.
    final now = DateTime(2026, 11, 23, 10);
    test('relance : 3 jours après la dernière séance, puis +2 et +4 jours', () {
      final slots = reminderSlots(const ReminderSettings(days: 3, hour: 18), now: now, lastSession: DateTime(2026, 11, 22));
      expect(slots.map((x) => x.when).toList(), [DateTime(2026, 11, 25, 18), DateTime(2026, 11, 27, 18), DateTime(2026, 11, 29, 18)]);
      expect(slots.first.daysSince, 3);
    });
    test('relance déjà dépassée : ce soir à l’heure choisie, ou demain si l’heure est passée', () {
      const s = ReminderSettings(days: 2, hour: 18);
      expect(reminderSlots(s, now: now, lastSession: DateTime(2026, 11, 10)).first.when, DateTime(2026, 11, 23, 18));
      final late = DateTime(2026, 11, 23, 20);
      expect(reminderSlots(s, now: late, lastSession: DateTime(2026, 11, 10)).first.when, DateTime(2026, 11, 24, 18));
    });
    test('sans aucune séance : compte à partir d’aujourd’hui', () {
      final slots = reminderSlots(const ReminderSettings(days: 2), now: now);
      expect(slots.first.when, DateTime(2026, 11, 25, 18));
      expect(slots.first.daysSince, isNull);
      expect(reminderText(const ReminderSettings(), slots.first, 'A').title, contains('première'));
    });
    test('jours fixes : lundi, mercredi, vendredi, sauf un jour déjà fait', () {
      const s = ReminderSettings(mode: ReminderMode.fixe, weekdays: {1, 3, 5}, hour: 18);
      final slots = reminderSlots(s, now: now, horizonDays: 6);
      expect(slots.map((x) => x.when).toList(), [DateTime(2026, 11, 23, 18), DateTime(2026, 11, 25, 18), DateTime(2026, 11, 27, 18)]);
      final done = reminderSlots(s, now: now, lastSession: DateTime(2026, 11, 23), horizonDays: 6);
      expect(done.first.when, DateTime(2026, 11, 25, 18));
    });
    test('désactivés : rien', () {
      expect(reminderSlots(const ReminderSettings(mode: ReminderMode.off), now: now), isEmpty);
    });
    test('réglages enregistrés puis relus à l’identique', () {
      const s = ReminderSettings(mode: ReminderMode.fixe, days: 4, hour: 7, minute: 30, weekdays: {2, 6});
      final back = ReminderSettings.fromJson(s.toJson());
      expect(back.toJson(), s.toJson());
      expect(back.summary, 'Mar, Sam à 07:30');
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
