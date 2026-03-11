import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Color primario por defecto (fallback) ────────────────────────────────────
const kPrimary      = Color(0xFF4ECDC4);

// ── Colores fijos (no dinámicos) ─────────────────────────────────────────────
const kBackground   = Color(0xFFFFFFFF);
const kSurface      = Color(0xFF1C1C1E);
const kCard         = Color(0xFF1C1C1E);
const kCardElevated = Color(0xFF232325);
const kCardDark2    = Color(0xFF2C2C2E);
const kDivider      = Color(0xFF2C2C2E);

const kText         = Color(0xFFFFFFFF);
const kTextSub      = Color(0xFFA1A1A6);
const kTextMuted    = Color(0xFF6E6E73);

const kPrimaryLight = Color(0xFF2C2C2E);
const kCardDark     = Color(0xFF232325);
const kShadow       = Color(0x80000000);

const kNeumorphicShadows = [
  BoxShadow(color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 6)),
  BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 4, offset: Offset(0, 2), spreadRadius: -1),
];

const kNeumorphicShadowsSmall = [
  BoxShadow(color: Color(0x80000000), blurRadius: 8, offset: Offset(0, 3)),
  BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 2, offset: Offset(0, 1), spreadRadius: -1),
];

const kNeumorphicShadowsInset = [
  BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(2, 2), spreadRadius: -1),
];

// ── Tema dinámico — recibe el color primario como parámetro ──────────────────
ThemeData crearTema(Color primario) => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBackground,
  colorScheme: ColorScheme.dark(
    primary: primario,
    secondary: primario,
    surface: kSurface,
    onPrimary: Colors.white,
    onSurface: kText,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBackground,
    foregroundColor: Color(0xFF1C1C1E),
    elevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: TextStyle(
      color: Color(0xFF1C1C1E),
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: kCard,
    indicatorColor: primario.withOpacity(0.2),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: kText, fontSize: 11, fontWeight: FontWeight.w600);
      }
      return const TextStyle(color: kTextSub, fontSize: 11);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: primario);
      }
      return const IconThemeData(color: kTextSub);
    }),
  ),
  cardTheme: CardThemeData(
    color: kCard,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kCardDark2,
    labelStyle: const TextStyle(color: kTextSub),
    hintStyle: const TextStyle(color: kTextMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primario, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primario,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: primario),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kTextSub,
      side: const BorderSide(color: kDivider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: kDivider, space: 1, thickness: 1),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? primario : Colors.white),
    trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? primario.withOpacity(0.5) : kCardDark2),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: kCardDark2,
    labelStyle: const TextStyle(color: kTextSub, fontWeight: FontWeight.w500),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(color: kText),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: kCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w600),
    contentTextStyle: const TextStyle(color: kTextSub),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: kCardElevated,
    contentTextStyle: const TextStyle(color: kText),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: primario,
    unselectedLabelColor: kTextSub,
    indicatorColor: primario,
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: kCard,
    textColor: kText,
    iconColor: kTextSub,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: primario,
    foregroundColor: Colors.white,
    elevation: 6,
  ),
);

// ── Tema por defecto (con kPrimary) ──────────────────────────────────────────
final temaApp = crearTema(kPrimary);

// ── Extensión para acceder al color primario dinámico desde cualquier widget ─
extension AppColorsExt on BuildContext {
  Color get colorPrimario => Theme.of(this).colorScheme.primary;
}
