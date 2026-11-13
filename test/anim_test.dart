// Vérifie les 32 animations sans téléphone : aucune ne plante, aucune ne produit de coordonnée invalide,
// et aucun membre ne passe sous le sol (le défaut corrigé sur les animations web).
import 'dart:ui';

import 'package:fit_home/anim/exercise_anims.dart';
import 'package:fit_home/anim/stage.dart';
import 'package:fit_home/data/programme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque exercice a son animation', () {
    for (final id in exercises.keys) {
      expect(exerciseAnims.containsKey(id), isTrue, reason: 'animation manquante : $id');
    }
  });

  const limbTags = {'leg', 'farleg', 'arm', 'fararm', 'torso'};
  for (final entry in exerciseAnims.entries) {
    test('${entry.key} : rien sous le sol, pas de NaN', () {
      var lowest = -1e9;
      String where = '';
      for (var i = 0; i <= 400; i++) {
        final t = i * 0.02;
        final s = Scene();
        entry.value.fn(s, t);
        for (final sh in s.shapes) {
          if (sh is StrokeShape) {
            for (final p in sh.pts) {
              expect(p.dx.isFinite && p.dy.isFinite, isTrue, reason: '${entry.key} t=$t : point invalide');
            }
            if (limbTags.contains(sh.tag)) {
              for (final p in sh.pts) {
                final y = p.dy + sh.halfWidth;
                if (y > lowest) {
                  lowest = y;
                  where = '${sh.tag} à t=${t.toStringAsFixed(2)}';
                }
              }
            }
          } else if (sh is CircleShape && sh.tag == 'head') {
            final y = sh.center.dy + sh.r;
            if (y > lowest) {
              lowest = y;
              where = 'tête à t=${t.toStringAsFixed(2)}';
            }
          }
        }
      }
      expect(lowest, lessThanOrEqualTo(886), reason: '${entry.key} : $where descend à y=$lowest (sol à 878)');
    });
  }

  test('le peintre dessine chaque animation sans erreur', () {
    for (final entry in exerciseAnims.entries) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final s = Scene();
      entry.value.fn(s, 1.3);
      for (final sh in s.shapes) {
        sh.paint(canvas);
      }
      recorder.endRecording().dispose();
    }
  });
}
