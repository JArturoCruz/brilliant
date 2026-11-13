import 'package:flutter/material.dart';

class TemaMesa {
  static const papel = Color(0xFFF4EBD8);
  static const papelClaro = Color(0xFFFFFBF2);
  static const tinta = Color(0xFF34291F);
  static const nogal = Color(0xFF68452D);
  static const nogalOscuro = Color(0xFF3F2B20);
  static const verde = Color(0xFF386641);
  static const dorado = Color(0xFFC28A35);
  static const numeroTablero = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(color: Colors.black87, offset: Offset(-0.7, 0)),
      Shadow(color: Colors.black87, offset: Offset(0.7, 0)),
      Shadow(color: Colors.black87, offset: Offset(0, -0.7)),
      Shadow(color: Colors.black87, offset: Offset(0, 0.7)),
      Shadow(color: Colors.black87, offset: Offset(-0.5, -0.5)),
      Shadow(color: Colors.black87, offset: Offset(0.5, -0.5)),
      Shadow(color: Colors.black87, offset: Offset(-0.5, 0.5)),
      Shadow(color: Colors.black87, offset: Offset(0.5, 0.5)),
    ],
  );

  static ThemeData get data {
    final scheme = ColorScheme.fromSeed(
      seedColor: verde,
      brightness: Brightness.light,
      primary: verde,
      onPrimary: Colors.white,
      secondary: dorado,
      onSecondary: tinta,
      surface: papelClaro,
      onSurface: tinta,
      error: const Color(0xFF9B332B),
    );
    final textTheme = ThemeData.light().textTheme.apply(
      bodyColor: tinta,
      displayColor: nogalOscuro,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: papel,
      appBarTheme: const AppBarTheme(
        backgroundColor: nogalOscuro,
        foregroundColor: papelClaro,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: papelClaro,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: papelClaro,
        elevation: 2,
        shadowColor: nogalOscuro.withAlpha(35),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: nogal.withAlpha(55)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: papelClaro,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: nogal.withAlpha(90)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: nogal.withAlpha(90)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: verde, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: verde,
          side: BorderSide(color: verde.withAlpha(150)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: nogalOscuro,
        contentTextStyle: const TextStyle(color: papelClaro),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: nogal.withAlpha(55), thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme.copyWith(
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class IndicadorCargaMesa extends StatelessWidget {
  const IndicadorCargaMesa({
    this.mensaje = 'Preparando la partida...',
    super.key,
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.82, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: TemaMesa.nogal,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: TemaMesa.dorado, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33402C20),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.casino_rounded,
                size: 38,
                color: TemaMesa.papelClaro,
              ),
            ),
            const SizedBox(height: 14),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const SizedBox(
              width: 132,
              child: LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
