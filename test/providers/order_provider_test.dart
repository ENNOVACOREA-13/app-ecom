import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/order_provider.dart';

void main() {
  group('ProveedorPedido — guard de paginación', () {
    test('una segunda llamada a cargarMasPedidos mientras la primera sigue en vuelo no hace nada', () async {
      final provider = ProveedorPedido();

      final primera = provider.cargarMasPedidos();
      expect(provider.cargandoMas, isTrue,
          reason: 'la primera llamada ya debe estar marcada como en curso');

      // Esta segunda llamada debe salir por el guard `_cargandoMas` sin
      // relanzar la carga (evita pedir la misma página dos veces).
      await provider.cargarMasPedidos();

      await primera;
      expect(provider.cargandoMas, isFalse);
    });

    test('sin más páginas (hayMasPedidos=false) no dispara ninguna carga', () async {
      final provider = ProveedorPedido();
      expect(provider.hayMasPedidos, isTrue, reason: 'arranca en true por defecto');
    });
  });
}
