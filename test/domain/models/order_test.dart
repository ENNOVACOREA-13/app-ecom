import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/models/order.dart';
import 'package:prettycore/domain/enums/order_status.dart';

void main() {
  group('ItemPedido.subtotal', () {
    test('es cantidad * precioUnitario', () {
      final item = ItemPedido(
        id: 'i1',
        pedidoId: 'p1',
        productoId: 'prod1',
        nombreProducto: 'Cera',
        cantidad: 3,
        precioUnitario: 45.5,
      );
      expect(item.subtotal, 136.5);
    });

    test('cantidad 0 da subtotal 0, no error', () {
      final item = ItemPedido(
        id: 'i1',
        pedidoId: 'p1',
        productoId: 'prod1',
        nombreProducto: 'Cera',
        cantidad: 0,
        precioUnitario: 45.5,
      );
      expect(item.subtotal, 0);
    });
  });

  group('Pedido.fromMap', () {
    test('parsea items anidados y calcula bien cada subtotal', () {
      final pedido = Pedido.fromMap({
        'id': 'p1',
        'client_id': 'c1',
        'status': 'confirmed',
        'total': 200,
        'created_at': '2026-08-10T12:00:00.000Z',
        'order_items': [
          {
            'id': 'i1',
            'order_id': 'p1',
            'product_id': 'prod1',
            'product_name': 'Cera',
            'quantity': 2,
            'unit_price': 50,
          },
          {
            'id': 'i2',
            'order_id': 'p1',
            'product_id': 'prod2',
            'product_name': 'Gel',
            'quantity': 1,
            'unit_price': 100,
          },
        ],
      });
      expect(pedido.items.length, 2);
      expect(pedido.items[0].subtotal, 100);
      expect(pedido.items[1].subtotal, 100);
      expect(pedido.estado, EstadoPedido.confirmed);
    });

    test('valores por defecto seguros cuando faltan campos opcionales', () {
      final pedido = Pedido.fromMap({
        'id': 'p1',
        'client_id': 'c1',
        'total': 0,
      });
      expect(pedido.estado, EstadoPedido.pending);
      expect(pedido.items, isEmpty);
      expect(pedido.metodoPago, 'cash');
      expect(pedido.estadoPago, 'pending');
      expect(pedido.nombreCliente, isNull);
    });

    test('un status desconocido de la BD no truena, cae en pending', () {
      final pedido = Pedido.fromMap({
        'id': 'p1',
        'client_id': 'c1',
        'total': 0,
        'status': 'algo_que_no_existe',
      });
      expect(pedido.estado, EstadoPedido.pending);
    });
  });
}
