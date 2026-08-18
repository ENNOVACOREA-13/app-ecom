import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/session_context.dart';

SessionContext _contexto(String role) => SessionContext(
      userId: 'u1',
      role: role,
      appIds: const [],
      permissions: const {},
    );

void main() {
  group('SessionContext', () {
    test('isAdmin es true para admin y admin_supremo', () {
      expect(_contexto('admin').isAdmin, isTrue);
      expect(_contexto('admin_supremo').isAdmin, isTrue);
      expect(_contexto('empleado').isAdmin, isFalse);
      expect(_contexto('usuario').isAdmin, isFalse);
    });

    test('isEmpleado es true solo para empleado', () {
      expect(_contexto('empleado').isEmpleado, isTrue);
      expect(_contexto('admin').isEmpleado, isFalse);
    });

    test('canEditProducts es true para admin, admin_supremo y empleado, no para usuario', () {
      expect(_contexto('admin').canEditProducts, isTrue);
      expect(_contexto('admin_supremo').canEditProducts, isTrue);
      expect(_contexto('empleado').canEditProducts, isTrue);
      expect(_contexto('usuario').canEditProducts, isFalse);
    });

    test('un rol desconocido no obtiene ningún permiso elevado', () {
      final ctx = _contexto('rol_inexistente');
      expect(ctx.isAdmin, isFalse);
      expect(ctx.isEmpleado, isFalse);
      expect(ctx.canEditProducts, isFalse);
    });
  });
}
