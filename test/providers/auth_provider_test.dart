import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/auth_provider.dart';

void main() {
  group('parsearErrorAuth', () {
    test('cuenta desactivada da mensaje específico', () {
      expect(parsearErrorAuth('account_deactivated'),
          'Tu cuenta ha sido desactivada. Contacta al administrador');
    });

    test('credenciales inválidas da mensaje específico', () {
      expect(parsearErrorAuth('AuthApiException: Invalid login credentials'),
          'Email o contraseña incorrectos');
    });

    test('email ya registrado da mensaje específico', () {
      expect(parsearErrorAuth('User already registered'), 'Este email ya está registrado');
    });

    test('rate limit da mensaje específico', () {
      expect(parsearErrorAuth('Email rate limit exceeded'), 'Demasiados intentos. Espera unos minutos');
    });

    test('error RLS no expone el código de Postgres crudo al usuario', () {
      final mensaje = parsearErrorAuth('new row violates row-level security policy for table "profiles"');
      expect(mensaje, 'Error de permisos en la base de datos. Contacta al administrador');
    });

    // Regresión: el mismo bug de mayúsculas que en booking/order/product
    // (ver commit "Vuelve testeables los providers") también estaba en el
    // mapeador de auth — el flujo más visitado de toda la app. Sin esto, un
    // usuario sin conexión veía "Ocurrió un error inesperado" en vez de
    // "Sin conexión a internet" justo en la pantalla de login.
    test('detecta un SocketException real sin conexión', () {
      final e = const SocketException('Connection refused');
      expect(parsearErrorAuth(e.toString()), 'Sin conexión a internet');
    });

    test('detecta un TimeoutException real', () {
      final e = TimeoutException('Future not completed', const Duration(seconds: 4));
      expect(parsearErrorAuth(e.toString()), 'La solicitud tardó demasiado. Intenta de nuevo');
    });

    test('un error totalmente desconocido no expone detalles internos del servidor', () {
      final mensaje = parsearErrorAuth('PostgrestException: unexpected token at line 42');
      expect(mensaje, 'Ocurrió un error inesperado. Intenta de nuevo');
      expect(mensaje.contains('token'), isFalse);
    });
  });
}
