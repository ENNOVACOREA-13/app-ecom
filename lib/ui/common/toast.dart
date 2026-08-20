import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum TipoToast { exito, error, info }

/// Muestra un snackbar flotante con estilo unificado (color según [tipo],
/// esquinas redondeadas, sin bordear de lado a lado). Reemplaza las
/// llamadas ad-hoc a ScaffoldMessenger.showSnackBar dispersas por la app.
void mostrarToast(BuildContext context, String mensaje, {TipoToast tipo = TipoToast.info}) {
  final color = switch (tipo) {
    TipoToast.exito => const Color(0xFF34C759),
    TipoToast.error => const Color(0xFFFF3B30),
    TipoToast.info => context.colorPrimario,
  };
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
}
