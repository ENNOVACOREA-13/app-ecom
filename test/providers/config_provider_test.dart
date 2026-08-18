import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/config_provider.dart';
import 'package:prettycore/data/config_repository.dart';

void main() {
  group('modoVistaPrevia', () {
    test('arranca desactivado', () {
      final provider = ProveedorConfig();
      expect(provider.modoVistaPrevia, isFalse);
    });

    test('activarVistaPrevia / desactivarVistaPrevia alternan el estado', () {
      final provider = ProveedorConfig();
      provider.activarVistaPrevia();
      expect(provider.modoVistaPrevia, isTrue);
      provider.desactivarVistaPrevia();
      expect(provider.modoVistaPrevia, isFalse);
    });
  });

  group('getters *Efectivo', () {
    test('usan el valor en vivo cuando no hay vista previa activa', () {
      final provider = ProveedorConfig();
      const nuevoColor = Color(0xFF123456);
      // Fire-and-forget: la asignación del borrador es síncrona; el intento
      // de guardarlo en el servidor fallará sin Supabase inicializado, pero
      // eso no nos importa para esta prueba — solo el estado local.
      unawaited(provider.actualizarBorradorColor(nuevoColor).catchError((_) => false));

      expect(provider.colorPrimarioBorrador, nuevoColor,
          reason: 'el borrador se actualiza aunque el guardado en el servidor falle');
      expect(provider.colorPrimarioEfectivo, isNot(nuevoColor),
          reason: 'sin vista previa activa, el valor efectivo debe ser el publicado, no el borrador');
    });

    test('usan el valor de borrador cuando la vista previa está activa', () {
      final provider = ProveedorConfig();
      const nuevoColor = Color(0xFF123456);
      unawaited(provider.actualizarBorradorColor(nuevoColor).catchError((_) => false));

      provider.activarVistaPrevia();
      expect(provider.colorPrimarioEfectivo, nuevoColor);

      provider.desactivarVistaPrevia();
      expect(provider.colorPrimarioEfectivo, isNot(nuevoColor),
          reason: 'al salir de vista previa, vuelve a mostrar el valor publicado');
    });
  });

  group('completarSeccionesHome', () {
    test('agrega al inicio las secciones por defecto que falten, sin duplicar las existentes', () {
      final resultado = completarSeccionesHome([
        {'key': 'productos', 'visible': false},
      ]);
      final claves = resultado.map((s) => s['key']).toList();
      expect(claves.where((k) => k == 'productos').length, 1,
          reason: 'no debe duplicar una sección que el sysadmin ya configuró');
      expect(claves.contains('chips_categorias'), isTrue);
      expect(claves.contains('banner_hero'), isTrue);
      // La configuración explícita del sysadmin se conserva tal cual.
      final productos = resultado.firstWhere((s) => s['key'] == 'productos');
      expect(productos['visible'], isFalse);
    });

    test('una lista vacía se completa con todas las secciones por defecto', () {
      final resultado = completarSeccionesHome(const []);
      expect(resultado.length, kSeccionesHomePorDefecto.length);
    });
  });
}
