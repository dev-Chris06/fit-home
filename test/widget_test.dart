// Test de fumée : l'app démarre et affiche l'accueil avec la séance A proposée.
import 'package:fit_home/app_state.dart';
import 'package:fit_home/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('l’accueil propose la séance A', (tester) async {
    SharedPreferences.setMockInitialValues({'autoUpdateCheck': false});
    await app.load();
    await tester.pumpWidget(const FitHomeApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Fit Home'), findsWidgets);
    expect(find.text('Commencer la séance A'), findsOneWidget);
  });
}
