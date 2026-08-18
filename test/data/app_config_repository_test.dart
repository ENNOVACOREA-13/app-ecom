import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/app_config_repository.dart';
import 'package:prettycore/domain/models/app_config.dart';

void main() {
  group('ControlTemaLogin', () {
    test('convierte un hex de 6 dígitos a Color opaco (alpha FF)', () {
      final control = ControlTemaLogin();
      control.aplicar(ConfigApp(
        idApp: 'a1',
        slug: 'demo',
        nombre: 'Demo',
        colorPrimario: '#7C3AED',
        colorFondo: '#000000',
      ));
      expect(control.colorPrimario, const Color(0xFF7C3AED));
      expect(control.colorFondo, const Color(0xFF000000));
    });

    test('funciona sin el símbolo #', () {
      final control = ControlTemaLogin();
      control.aplicar(ConfigApp(
        idApp: 'a1',
        slug: 'demo',
        nombre: 'Demo',
        colorPrimario: '7C3AED',
        colorFondo: '000000',
      ));
      expect(control.colorPrimario, const Color(0xFF7C3AED));
    });

    test('valores por defecto antes de aplicar ninguna config', () {
      final control = ControlTemaLogin();
      expect(control.colorPrimario, const Color(0xFF7C3AED));
      expect(control.colorFondo, const Color(0xFF000000));
    });
  });
}
