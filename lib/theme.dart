// Les couleurs et le thème de l'app : les mêmes que les animations (bleu nuit, vert menthe, orange).
import 'package:flutter/material.dart';

class Palette {
  static const ground = Color(0xFF0F2236); // fond bleu nuit
  static const surface = Color(0xFF15304A); // cartes
  static const surfaceHigh = Color(0xFF1C3B58);
  static const main = Color(0xFF3DDC97); // vert menthe : la silhouette, les actions principales
  static const second = Color(0xFFF2F5F7); // texte
  static const accent = Color(0xFFFF7A59); // orange : muscle travaillé, haltères, alertes douces
  static const muted = Color(0xFF9FB3C2);
  static const line = Color(0xFF2B4660);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Palette.main,
    onPrimary: Palette.ground,
    secondary: Palette.accent,
    onSecondary: Palette.ground,
    surface: Palette.surface,
    onSurface: Palette.second,
    error: Palette.accent,
    onError: Palette.ground,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.ground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.ground,
      foregroundColor: Palette.second,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Palette.surface,
      indicatorColor: Color(0xFF235C4A),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.main,
        foregroundColor: Palette.ground,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.second,
        minimumSize: const Size(64, 48),
        side: const BorderSide(color: Palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.ground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Palette.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Palette.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Palette.main, width: 2)),
    ),
  );
}

/// Petite étiquette en capitales, comme « EXERCICE 2 / 7 · PECTORAUX » dans les animations.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = Palette.accent});
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      );
}

/// Une carte simple avec la couleur de surface du thème.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color = Palette.surface});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
