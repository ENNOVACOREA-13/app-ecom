import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/models/tenant.dart';

void main() {
  group('Tenant.fromMap — admins', () {
    test('sin profiles ni membresías, la lista queda vacía', () {
      final t = Tenant.fromMap({
        'id': 't1',
        'slug': 'pretty',
        'business_name': 'PrettyCore',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(t.admins, isEmpty);
    });

    test('excluye platform_admin de los admins "de casa"', () {
      final t = Tenant.fromMap({
        'id': 't1',
        'slug': 'pretty',
        'business_name': 'PrettyCore',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
        'profiles': [
          {'id': 'u1', 'full_name': 'Admin Casa', 'email': 'a@x.com', 'role': 'admin'},
          {'id': 'u2', 'full_name': 'Plataforma', 'email': 'p@x.com', 'role': 'platform_admin'},
        ],
      });
      expect(t.admins.map((a) => a.id), ['u1']);
    });

    // Regresión: un admin/sysadmin invitado a un SEGUNDO negocio (vía
    // user_tenant_memberships, ver migración 20260819130000) tiene su
    // profiles.tenant_id apuntando a su negocio "de casa" — sin la
    // membresía, ese negocio nuevo lo veía como si no tuviera ningún admin.
    test('agrega admins que solo llegan por membresía (no por profiles.tenant_id)', () {
      final t = Tenant.fromMap(
        {
          'id': 'pretty-id',
          'slug': 'pretty',
          'business_name': 'PrettyCore',
          'status': 'active',
          'created_at': '2026-01-01T00:00:00Z',
          'profiles': [], // nadie tiene su tenant_id "de casa" en PrettyCore
        },
        membresias: [
          {'tenant_id': 'pretty-id', 'user_id': 'u3', 'role': 'sysadmin'},
        ],
        perfilesPorId: {
          'u3': {'id': 'u3', 'full_name': 'Sysadmin Viajero', 'email': 's@x.com'},
        },
      );

      expect(t.admins, hasLength(1));
      expect(t.admins.first.id, 'u3');
      expect(t.admins.first.rol, 'sysadmin');
      expect(t.admins.first.email, 's@x.com');
      expect(t.admins.first.nombreCompleto, 'Sysadmin Viajero');
    });

    test('no duplica una cuenta que aparece por profiles Y por membresía — gana la membresía', () {
      final t = Tenant.fromMap(
        {
          'id': 'mc-id',
          'slug': 'mc-barber',
          'business_name': 'MC Barber',
          'status': 'active',
          'created_at': '2026-01-01T00:00:00Z',
          'profiles': [
            {'id': 'u1', 'full_name': 'Viejo Nombre', 'email': 'viejo@x.com', 'role': 'admin'},
          ],
        },
        membresias: [
          {'tenant_id': 'mc-id', 'user_id': 'u1', 'role': 'super_admin'},
        ],
        perfilesPorId: {
          'u1': {'id': 'u1', 'full_name': 'Nombre Actual', 'email': 'actual@x.com'},
        },
      );

      expect(t.admins, hasLength(1));
      expect(t.admins.first.rol, 'super_admin');
      expect(t.admins.first.email, 'actual@x.com');
    });

    test('ignora membresías de otros tenants', () {
      final t = Tenant.fromMap(
        {
          'id': 'pretty-id',
          'slug': 'pretty',
          'business_name': 'PrettyCore',
          'status': 'active',
          'created_at': '2026-01-01T00:00:00Z',
        },
        membresias: [
          {'tenant_id': 'otro-id', 'user_id': 'u9', 'role': 'admin'},
        ],
        perfilesPorId: {
          'u9': {'id': 'u9', 'full_name': 'De otro negocio', 'email': 'o@x.com'},
        },
      );

      expect(t.admins, isEmpty);
    });
  });

  group('combinarCuentasAdmin', () {
    test('un id sin fila en perfilesPorId no truena, queda con nombre/email nulos', () {
      final resultado = combinarCuentasAdmin(
        deProfiles: const [],
        membresias: [
          {'user_id': 'u1', 'role': 'admin'},
        ],
        perfilesPorId: const {},
      );

      expect(resultado, hasLength(1));
      expect(resultado.first.id, 'u1');
      expect(resultado.first.nombreCompleto, isNull);
      expect(resultado.first.email, isNull);
    });
  });
}
