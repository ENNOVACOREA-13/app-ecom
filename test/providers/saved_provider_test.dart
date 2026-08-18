import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/saved_provider.dart';

void main() {
  group('ProveedorGuardados', () {
    test('toggleGuardado sin usuario cargado no hace nada', () async {
      final provider = ProveedorGuardados();
      await provider.toggleGuardado('p1');
      expect(provider.estaGuardado('p1'), isFalse);
    });

    test('el update optimista se revierte si falla el guardado en el servidor', () async {
      final provider = ProveedorGuardados();
      // cargar() intenta traer la lista real de Supabase (falla sin
      // inicializar, queda atrapado en su propio catch) pero sí deja
      // _userId asignado, que es lo que necesita toggleGuardado.
      await provider.cargar('u1');
      expect(provider.estaGuardado('p1'), isFalse);

      // Optimista: agrega 'p1' de inmediato, luego intenta persistirlo;
      // como el guardado en el servidor también falla, debe revertir.
      await provider.toggleGuardado('p1');

      expect(provider.estaGuardado('p1'), isFalse,
          reason: 'si el guardado en el servidor falla, no debe quedar marcado como guardado localmente');
    });

    test('limpiar borra el estado y el usuario asociado', () async {
      final provider = ProveedorGuardados();
      await provider.cargar('u1');
      provider.limpiar();
      expect(provider.guardados, isEmpty);
      // Sin userId, toggleGuardado vuelve a ser un no-op.
      await provider.toggleGuardado('p1');
      expect(provider.estaGuardado('p1'), isFalse);
    });
  });
}
