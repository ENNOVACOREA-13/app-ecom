import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/enums/user_role.dart';
import 'package:prettycore/domain/models/profile.dart';

Perfil _perfil({required RolUsuario rol, String? tenantId}) => Perfil(
      id: 'u1',
      rol: rol,
      nombreCompleto: 'Alguien',
      estaActivo: true,
      creadoEn: DateTime(2026, 1, 1),
      tenantId: tenantId,
    );

void main() {
  group('perteneceATenant', () {
    // Regresión: mostrar "esta cuenta no tiene acceso aquí" a una cuenta
    // real de OTRO negocio confirma que el correo/contraseña existen en
    // algún lado — debe verse EXACTAMENTE igual que no pertenecer.
    test('cuenta de otro negocio no pertenece al dominio actual', () {
      final p = _perfil(rol: RolUsuario.admin, tenantId: 'mc-barber-id');
      expect(p.perteneceATenant('pretty-id'), isFalse);
    });

    test('cuenta del mismo negocio sí pertenece', () {
      final p = _perfil(rol: RolUsuario.admin, tenantId: 'pretty-id');
      expect(p.perteneceATenant('pretty-id'), isTrue);
    });

    test('dominio sin tenant (control plane) — solo platform_admin pertenece', () {
      expect(_perfil(rol: RolUsuario.admin, tenantId: 'mc-barber-id').perteneceATenant(null),
          isFalse);
      expect(_perfil(rol: RolUsuario.platformAdmin, tenantId: 'mc-barber-id').perteneceATenant(null),
          isTrue);
    });

    test('platform_admin pertenece a cualquier dominio con tenant real', () {
      final p = _perfil(rol: RolUsuario.platformAdmin, tenantId: 'mc-barber-id');
      expect(p.perteneceATenant('pretty-id'), isTrue);
      expect(p.perteneceATenant('mc-barber-id'), isTrue);
    });

    test('cliente/empleado solo pertenece a su propio tenant fijo', () {
      final cliente = _perfil(rol: RolUsuario.client, tenantId: 'mc-barber-id');
      expect(cliente.perteneceATenant('mc-barber-id'), isTrue);
      expect(cliente.perteneceATenant('pretty-id'), isFalse);
    });
  });
}
