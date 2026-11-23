// Test de fumée : l'app démarre et affiche l'accueil avec la séance A proposée.
import 'package:fit_home/app_state.dart';
import 'package:fit_home/main.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('l’accueil propose la séance A', (tester) async {
    SharedPreferences.setMockInitialValues({'autoUpdateCheck': false, 'remindersConfigured': true});
    await app.load();
    await tester.pumpWidget(const FitHomeApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Fit Home'), findsWidgets);
    expect(find.text('Commencer la séance A'), findsOneWidget);
  });

  testWidgets('premier lancement : le réglage des rappels s’ouvre', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'autoUpdateCheck': false});
    await app.load();
    await tester.pumpWidget(const FitHomeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Rappels'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(app.remindersConfigured, isTrue);
    expect(find.text('Commencer la séance A'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10)); // laisse le message en bas de l'écran disparaître
  });
}
