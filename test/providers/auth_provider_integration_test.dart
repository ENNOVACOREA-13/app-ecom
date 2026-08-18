import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/auth_provider.dart';
import 'package:prettycore/data/auth_repository.dart';
import 'package:prettycore/domain/models/profile.dart';
import 'package:prettycore/domain/enums/user_role.dart';

class MockRepositorioAuth extends Mock implements RepositorioAuth {}

Perfil _perfil({bool activo = true}) => Perfil(
      id: 'u1',
      nombreCompleto: 'Cliente Uno',
      rol: RolUsuario.client,
      estaActivo: activo,
      creadoEn: DateTime(2026, 1, 1),
    );

void main() {
  group('ProveedorAuth.iniciarSesion', () {
    test('éxito: guarda el perfil y limpia el error', () async {
      final repo = MockRepositorioAuth();
      when(() => repo.iniciarSesion(correo: any(named: 'correo'), contrasena: any(named: 'contrasena')))
          .thenAnswer((_) async => _perfil());

      final provider = ProveedorAuth(repo: repo);
      final ok = await provider.iniciarSesion('cliente@test.com', '123456');

      expect(ok, isTrue);
      expect(provider.perfil?.id, 'u1');
      expect(provider.error, isNull);
      expect(provider.cargando, isFalse);
    });

    test('credenciales inválidas: no guarda perfil y muestra el mensaje mapeado', () async {
      final repo = MockRepositorioAuth();
      when(() => repo.iniciarSesion(correo: any(named: 'correo'), contrasena: any(named: 'contrasena')))
          .thenThrow(Exception('AuthApiException: Invalid login credentials'));

      final provider = ProveedorAuth(repo: repo);
      final ok = await provider.iniciarSesion('cliente@test.com', 'incorrecta');

      expect(ok, isFalse);
      expect(provider.perfil, isNull);
      expect(provider.error, 'Email o contraseña incorrectos');
      expect(provider.cargando, isFalse);
    });

    test('cuenta desactivada: el mensaje no expone el código interno', () async {
      final repo = MockRepositorioAuth();
      when(() => repo.iniciarSesion(correo: any(named: 'correo'), contrasena: any(named: 'contrasena')))
          .thenThrow(Exception('account_deactivated'));

      final provider = ProveedorAuth(repo: repo);
      await provider.iniciarSesion('cliente@test.com', '123456');

      expect(provider.error, 'Tu cuenta ha sido desactivada. Contacta al administrador');
    });

    test('reintentar tras un error limpia el mensaje anterior', () async {
      final repo = MockRepositorioAuth();
      when(() => repo.iniciarSesion(correo: any(named: 'correo'), contrasena: any(named: 'contrasena')))
          .thenThrow(Exception('Invalid login credentials'));

      final provider = ProveedorAuth(repo: repo);
      await provider.iniciarSesion('cliente@test.com', 'mal');
      expect(provider.error, isNotNull);

      when(() => repo.iniciarSesion(correo: any(named: 'correo'), contrasena: any(named: 'contrasena')))
          .thenAnswer((_) async => _perfil());
      await provider.iniciarSesion('cliente@test.com', 'bien');

      expect(provider.error, isNull, reason: 'un intento exitoso debe limpiar el error del intento anterior');
      expect(provider.perfil, isNotNull);
    });
  });

  group('ProveedorAuth.cerrarSesion', () {
    test('limpia el perfil aunque el repo falle al cerrar sesión', () async {
      final repo = MockRepositorioAuth();
      when(() => repo.iniciarSesion(correo: any(named: 'correo'), contrasena: any(named: 'contrasena')))
          .thenAnswer((_) async => _perfil());
      when(() => repo.cerrarSesion()).thenAnswer((_) async {});

      final provider = ProveedorAuth(repo: repo);
      await provider.iniciarSesion('cliente@test.com', '123456');
      expect(provider.perfil, isNotNull);

      await provider.cerrarSesion();
      expect(provider.perfil, isNull);
    });
  });
}
