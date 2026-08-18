import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/order_provider.dart';
import 'package:prettycore/data/order_repository.dart';
import 'package:prettycore/providers/cart_provider.dart';
import 'package:prettycore/domain/models/product.dart';
import 'package:prettycore/domain/enums/product_status.dart';

class MockRepositorioPedido extends Mock implements RepositorioPedido {}

class FakeItemCarrito extends Fake implements ItemCarrito {}

List<ItemCarrito> _carritoConUnProducto() {
  final producto = Producto(
    id: 'p1',
    nombre: 'Cera',
    precio: 50,
    existencias: 10,
    estado: EstadoProducto.active,
    creadoPor: 'u1',
    creadoEn: DateTime(2026, 1, 1),
  );
  return [ItemCarrito(producto: producto, cantidad: 2)];
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeItemCarrito());
  });

  group('realizarPedido', () {
    test('éxito: devuelve true y limpia cualquier error previo', () async {
      final repo = MockRepositorioPedido();
      when(() => repo.crearPedido(
            clienteId: any(named: 'clienteId'),
            items: any(named: 'items'),
            notas: any(named: 'notas'),
            metodoPago: any(named: 'metodoPago'),
            estadoPago: any(named: 'estadoPago'),
            stripePaymentId: any(named: 'stripePaymentId'),
          )).thenAnswer((_) async => 'pedido-123');

      final provider = ProveedorPedido(repo: repo);
      final ok = await provider.realizarPedido(clienteId: 'c1', items: _carritoConUnProducto());

      expect(ok, isTrue);
      expect(provider.error, isNull);
      expect(provider.cargando, isFalse);
    });

    test('stock insuficiente: el error del servidor llega mapeado, sin exponer el código', () async {
      final repo = MockRepositorioPedido();
      when(() => repo.crearPedido(
            clienteId: any(named: 'clienteId'),
            items: any(named: 'items'),
            notas: any(named: 'notas'),
            metodoPago: any(named: 'metodoPago'),
            estadoPago: any(named: 'estadoPago'),
            stripePaymentId: any(named: 'stripePaymentId'),
          )).thenThrow(Exception('INSUFFICIENT_STOCK'));

      final provider = ProveedorPedido(repo: repo);
      final ok = await provider.realizarPedido(clienteId: 'c1', items: _carritoConUnProducto());

      expect(ok, isFalse);
      expect(provider.error, 'Uno de los productos ya no tiene stock suficiente. Revisa tu carrito.');
    });

    test('pasa los items del carrito tal cual al repo (product_id + cantidad los arma el repo)', () async {
      final repo = MockRepositorioPedido();
      when(() => repo.crearPedido(
            clienteId: any(named: 'clienteId'),
            items: any(named: 'items'),
            notas: any(named: 'notas'),
            metodoPago: any(named: 'metodoPago'),
            estadoPago: any(named: 'estadoPago'),
            stripePaymentId: any(named: 'stripePaymentId'),
          )).thenAnswer((_) async => 'pedido-123');

      final items = _carritoConUnProducto();
      final provider = ProveedorPedido(repo: repo);
      await provider.realizarPedido(clienteId: 'c1', items: items, metodoPago: 'card');

      verify(() => repo.crearPedido(
            clienteId: 'c1',
            items: items,
            notas: null,
            metodoPago: 'card',
            estadoPago: 'pending',
            stripePaymentId: null,
          )).called(1);
    });
  });
}
