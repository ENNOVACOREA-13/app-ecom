import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Colores principales del nuevo diseño oscuro ─────────────────────────────
const kPrimary      = Color(0xFF4ECDC4); // Teal acento (se mantiene)
const kBackground   = Color(0xFFFFFFFF); // Fondo principal blanco
const kSurface      = Color(0xFF1C1C1E); // Fondo de tarjetas y superficies
const kCard         = Color(0xFF1C1C1E); // Tarjetas (igual que surface)
const kCardElevated = Color(0xFF232325); // Para elementos ligeramente más claros (opcional)
const kCardDark2    = Color(0xFF2C2C2E); // Fondo de inputs, sliders, tracks
const kDivider      = Color(0xFF2C2C2E); // Divisor sutil

// Textos
const kText         = Color(0xFFFFFFFF); // Texto principal blanco
const kTextSub      = Color(0xFFA1A1A6); // Texto secundario gris claro
const kTextMuted    = Color(0xFF6E6E73); // Texto muy muted (para hints, etc.)

// ── Constantes legacy para compatibilidad con código existente ──────────────
// Ajustadas al nuevo tema oscuro (pueden refinarse más adelante)
const kPrimaryLight = Color(0xFF2C2C2E); // Se usaba antes como fondo claro; ahora es gris medio
const kCardDark     = Color(0xFF232325); // Ligeramente más claro que las tarjetas
const kShadow       = Color(0x80000000); // Negro semitransparente para sombras

// ── Sombras estilo neumórfico (adaptadas a fondo oscuro) ────────────────────
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

// ── Tema principal de la aplicación ─────────────────────────────────────────
final temaApp = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBackground,
  colorScheme: ColorScheme.dark(
    primary: kPrimary,
    secondary: kPrimary,
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
    indicatorColor: kPrimary.withOpacity(0.2),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: kText, fontSize: 11, fontWeight: FontWeight.w600);
      }
      return const TextStyle(color: kTextSub, fontSize: 11);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: kPrimary);
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
      borderSide: const BorderSide(color: kPrimary, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: kPrimary),
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
        s.contains(WidgetState.selected) ? kPrimary : Colors.white),
    trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? kPrimary.withOpacity(0.5) : kCardDark2),
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
  tabBarTheme: const TabBarThemeData(
    labelColor: kPrimary,
    unselectedLabelColor: kTextSub,
    indicatorColor: kPrimary,
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: kCard,
    textColor: kText,
    iconColor: kTextSub,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kPrimary,
    foregroundColor: Colors.white,
    elevation: 6,
  ),
);