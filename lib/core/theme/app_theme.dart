import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color primario por defecto (fallback) ────────────────────────────────────
const kPrimary      = Color(0xFF4ECDC4);

// ── Responsivo de escritorio ──────────────────────────────────────────────
// Ancho a partir del cual se considera "escritorio".
const kAnchoEscritorio = 700.0;

// Margen lateral en escritorio: un porcentaje del ancho de pantalla (con
// tope) para que la app siga sintiéndose responsiva —no un ancho fijo tipo
// móvil— y solo evite que el contenido se vea estirado de borde a borde.
double margenLateralEscritorio(double anchoPantalla) =>
    (anchoPantalla * 0.06).clamp(24.0, 90.0);

/// Envuelve el body de una página con márgenes laterales en escritorio;
/// en móvil no cambia nada. Pensado para envolver directamente el
/// `body:` de un `Scaffold` en páginas de una sola columna (listas,
/// formularios, dashboards). Para páginas con elementos decorativos
/// de borde a borde (imágenes, encabezados curvos) aplica el margen
/// manualmente solo al contenido, no al `body` completo.
class EnvolturaResponsiva extends StatelessWidget {
  final Widget child;
  const EnvolturaResponsiva({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    if (ancho < kAnchoEscritorio) return child;
    final margen = margenLateralEscritorio(ancho);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margen),
      child: child,
    );
  }
}

/// Igual que [EnvolturaResponsiva], pero para pantallas de formulario
/// (login, registro, recuperar contraseña): en escritorio centra el
/// contenido en una columna angosta tipo tarjeta en vez de solo
/// agregar márgenes, porque un formulario estirado a todo lo ancho
/// se ve mal.
class EnvolturaFormularioResponsivo extends StatelessWidget {
  final Widget child;
  final double anchoMaximo;
  const EnvolturaFormularioResponsivo({
    super.key,
    required this.child,
    this.anchoMaximo = 460,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    if (ancho < kAnchoEscritorio) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: child,
      ),
    );
  }
}

// ── Colores fijos (no dinámicos) ─────────────────────────────────────────────
// No es `const`: el sysadmin/admin puede cambiarlo en tiempo de ejecución
// desde el Diseñador de vista (color secundario) — ver ProveedorConfig.
Color kBackground   = const Color(0xFFFFFFFF);
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

// ── Tema dinámico — recibe el color primario y el estilo como parámetros ─────
ThemeData crearTema(
  Color primario, {
  String fontFamily = 'Poppins',
  double radioContenedor = 16,
  double sombraContenedor = 1,
}) => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBackground,
  textTheme: GoogleFonts.getTextTheme(fontFamily, ThemeData.light().textTheme),
  colorScheme: ColorScheme.dark(
    primary: primario,
    secondary: primario,
    surface: kSurface,
    onPrimary: Colors.white,
    onSurface: kText,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kBackground,
    foregroundColor: const Color(0xFF1C1C1E),
    elevation: 0,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: GoogleFonts.getFont(
      fontFamily,
      textStyle: const TextStyle(
        color: Color(0xFF1C1C1E),
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioContenedor)),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF2F2F7),
    labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
    hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioContenedor)),
    titleTextStyle: GoogleFonts.getFont(
      fontFamily,
      textStyle: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w600),
    ),
    contentTextStyle: GoogleFonts.getFont(
      fontFamily,
      textStyle: const TextStyle(color: kTextSub),
    ),
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
