import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/services/role_service.dart';

void main() {
  const roles = [
    RoleService.usuario,
    RoleService.empleado,
    RoleService.admin,
    RoleService.adminSupremo,
  ];

  group('esAdmin', () {
    test('solo admin y admin_supremo son admin', () {
      expect(RoleService.esAdmin(RoleService.admin), isTrue);
      expect(RoleService.esAdmin(RoleService.adminSupremo), isTrue);
      expect(RoleService.esAdmin(RoleService.empleado), isFalse);
      expect(RoleService.esAdmin(RoleService.usuario), isFalse);
    });
  });

  group('esEmpleado', () {
    test('solo el rol empleado exacto', () {
      expect(RoleService.esEmpleado(RoleService.empleado), isTrue);
      for (final rol in [RoleService.usuario, RoleService.admin, RoleService.adminSupremo]) {
        expect(RoleService.esEmpleado(rol), isFalse, reason: '$rol no es empleado');
      }
    });
  });

  group('puedeVerTodasLasReservas', () {
    test('solo admin y admin_supremo', () {
      expect(RoleService.puedeVerTodasLasReservas(RoleService.admin), isTrue);
      expect(RoleService.puedeVerTodasLasReservas(RoleService.adminSupremo), isTrue);
      expect(RoleService.puedeVerTodasLasReservas(RoleService.empleado), isFalse);
      expect(RoleService.puedeVerTodasLasReservas(RoleService.usuario), isFalse);
    });
  });

  group('puedeVerSoloSusReservas', () {
    test('solo usuario', () {
      expect(RoleService.puedeVerSoloSusReservas(RoleService.usuario), isTrue);
      for (final rol in [RoleService.empleado, RoleService.admin, RoleService.adminSupremo]) {
        expect(RoleService.puedeVerSoloSusReservas(rol), isFalse);
      }
    });
  });

  group('permisos de gestión de productos (crear/editar/eliminar/gestionar)', () {
    test('empleado, admin y admin_supremo pueden; usuario no', () {
      final permisos = [
        RoleService.puedeCrearProductos,
        RoleService.puedeEditarProductos,
        RoleService.puedeEliminarProductos,
        RoleService.puedeGestionarProductos,
      ];
      for (final permiso in permisos) {
        expect(permiso(RoleService.empleado), isTrue);
        expect(permiso(RoleService.admin), isTrue);
        expect(permiso(RoleService.adminSupremo), isTrue);
        expect(permiso(RoleService.usuario), isFalse);
      }
    });
  });

  test('un rol desconocido no obtiene ningún permiso elevado', () {
    const rolDesconocido = 'rol_inexistente';
    expect(RoleService.esAdmin(rolDesconocido), isFalse);
    expect(RoleService.esEmpleado(rolDesconocido), isFalse);
    expect(RoleService.puedeVerTodasLasReservas(rolDesconocido), isFalse);
    expect(RoleService.puedeGestionarProductos(rolDesconocido), isFalse);
    expect(RoleService.puedeVerSoloSusReservas(rolDesconocido), isFalse);
  });

  test('todos los roles pueden crear reservas', () {
    for (final rol in roles) {
      expect(RoleService.puedeCrearReservas(rol), isTrue);
    }
  });
}
