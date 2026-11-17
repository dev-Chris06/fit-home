// Point d'entrée : charge le journal enregistré sur le téléphone, puis affiche l'app.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/more_screen.dart';
import 'screens/sessions_screen.dart';
import 'theme.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const FitHomeApp());
}

class FitHomeApp extends StatelessWidget {
  const FitHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fit Home',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}

/// La coquille avec la barre de navigation du bas (4 onglets).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Vérification automatique des mises à jour, au plus une fois par jour et seulement si l'option est active.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (app.autoUpdateCheck && app.lastUpdateCheck != isoDate(DateTime.now()) && mounted) {
        runUpdateCheck(context, silent: true);
      }
    });
  }

  void _goTo(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenJournal: () => _goTo(2), onOpenSessions: () => _goTo(1)),
      const SessionsScreen(),
      const JournalScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      // TickerMode coupe les animations des onglets cachés (économie de batterie).
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [for (var i = 0; i < pages.length; i++) TickerMode(enabled: i == _tab, child: pages[i])],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Séances'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progrès'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Plus'),
        ],
      ),
    );
  }
}
