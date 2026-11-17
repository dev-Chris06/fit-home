// Captures d'écran de contrôle, prises par la CI (pas de téléphone nécessaire).
// Lancées avec : flutter test screenshots/ --update-goldens
// Les images sont publiées dans l'onglet Actions (artifact « captures ») pour vérifier l'interface à l'œil.
import 'dart:io';
import 'dart:typed_data';

import 'package:fit_home/anim/exercise_view.dart';
import 'package:fit_home/app_state.dart';
import 'package:fit_home/data/programme.dart';
import 'package:fit_home/main.dart';
import 'package:fit_home/screens/exercise_screen.dart';
import 'package:fit_home/screens/guided_session_screen.dart';
import 'package:fit_home/screens/session_detail_screen.dart';
import 'package:fit_home/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('$dir/$f');
      if (file.existsSync()) loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

Widget _wrap(Widget child) => MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(), home: child);

void main() {
  setUpAll(() async {
    await _loadFonts();
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  Future<void> shoot(WidgetTester tester, Widget w, String name, {Duration wait = const Duration(milliseconds: 1300)}) async {
    await phone(tester);
    await tester.pumpWidget(w);
    await tester.pump(wait);
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('captures/$name.png'));
  }

  testWidgets('accueil', (tester) async {
    SharedPreferences.setMockInitialValues({'autoUpdateCheck': false});
    await app.load();
    await app.addEntry(const JournalEntry(id: '1', date: '2026-11-10', type: 'A', reussi: true, charge: '2 bouteilles de 1,5 L', createdAt: '1'));
    await shoot(tester, const FitHomeApp(), '01-accueil');
  });

  testWidgets('séance A', (tester) async {
    await shoot(tester, _wrap(const SessionDetailScreen(session: sessionA)), '02-seance-a');
  });

  testWidgets('exercice', (tester) async {
    await shoot(tester, _wrap(const ExerciseScreen(exerciseId: 'militaire', reps: '3 × 10 à 12 répétitions')), '03-exercice');
  });

  testWidgets('séance guidée', (tester) async {
    await shoot(tester, _wrap(const GuidedSessionScreen(session: sessionC)), '04-seance-guidee');
  });

  testWidgets('séries, repos et fin de séance', (tester) async {
    SharedPreferences.setMockInitialValues({'autoUpdateCheck': false});
    await app.load();
    await phone(tester);
    await tester.pumpWidget(_wrap(const GuidedSessionScreen(session: sessionA)));
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Passer'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pump(const Duration(milliseconds: 1000));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('captures/08-serie.png'));
    await tester.tap(find.text('Série terminée'));
    await tester.pump(const Duration(milliseconds: 1000));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('captures/09-repos.png'));
    for (var i = 0; i < 80 && find.text('Terminer').evaluate().isEmpty; i++) {
      final skip = find.textContaining('Exercice suivant (');
      await tester.tap(skip.evaluate().isNotEmpty ? skip : find.textContaining('Passer'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('captures/10-fin.png'));
  });

  testWidgets('journal et plus', (tester) async {
    SharedPreferences.setMockInitialValues({'autoUpdateCheck': false});
    await app.load();
    await app.addEntry(const JournalEntry(id: '2', date: '2026-11-12', type: 'B', ressenti: 'dur', notes: 'pompes 10, 9, 8', createdAt: '2'));
    await phone(tester);
    await tester.pumpWidget(const FitHomeApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Progrès'));
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('captures/05-progres.png'));
    await tester.tap(find.text('Plus'));
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('captures/06-plus.png'));
  });

  testWidgets('les 32 animations', (tester) async {
    await phone(tester);
    final ids = exercises.keys.toList();
    await tester.pumpWidget(_wrap(Scaffold(
      body: GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(4),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: [for (final id in ids) ExerciseScreenThumb(id)],
      ),
    )));
    await tester.pump(const Duration(milliseconds: 1300));
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('captures/07-animations.png'));
  });
}

/// Une vignette d'animation pour la planche de contrôle.
class ExerciseScreenThumb extends StatelessWidget {
  final String id;
  const ExerciseScreenThumb(this.id, {super.key});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: ExerciseView(id)),
        Positioned(left: 4, bottom: 2, child: Text(id, style: const TextStyle(fontSize: 9, color: Colors.white))),
      ]);
}
