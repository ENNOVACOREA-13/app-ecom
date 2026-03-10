// lib/ui/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED); // morado principal
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color grey = Color(0xFFB0B0B0);
}

/// Control dinámico del tema (usado por LoginPage y AppShell)
class ControlTemaLogin extends ChangeNotifier {
  Color _colorPrimario = AppColors.primary;
  bool _temaOscuro = true;
  String? _logoBase64;

  ThemeData get theme =>
      _temaOscuro ? AppTheme.dark(_colorPrimario) : AppTheme.light(_colorPrimario);

  Color get colorPrimario => _colorPrimario;
  Color get colorFondo => _temaOscuro ? AppColors.black : AppColors.white;
  String? get logoBase64 => _logoBase64;

  void aplicar(dynamic cfg) {
    final hex = (cfg?['primaryColor'] as String?) ??
        (cfg?['primary'] as String?) ??
        (cfg?['color'] as String?);
    if (hex != null) _colorPrimario = _parseHex(hex);

    final logo = cfg?['logoBase64'] as String?;
    if (logo != null) _logoBase64 = logo;

    notifyListeners();
  }

  void alternar() {
    _temaOscuro = !_temaOscuro;
    notifyListeners();
  }

  Color _parseHex(String s) {
    final c = s.replaceAll('#', '');
    var v = int.parse(c, radix: 16);
    if (c.length == 6) v |= 0xFF000000;
    return Color(v);
  }
}

class AppTheme {
  static ThemeData light([Color colorSeed = AppColors.primary]) => ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: colorSeed,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
        ),
        cardColor: const Color(0xFFF2F2F2),
        useMaterial3: true,
      );

  static ThemeData dark([Color colorSeed = AppColors.primary]) => ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: colorSeed,
        scaffoldBackgroundColor: AppColors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
        ),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      );

  static ThemeData build() => dark();
}
