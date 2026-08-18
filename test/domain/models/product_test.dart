import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/domain/models/product.dart';
import 'package:prettycore/domain/enums/product_status.dart';

Producto _producto({
  double precio = 100,
  double? precioOferta,
  int existencias = 5,
  EstadoProducto estado = EstadoProducto.active,
}) {
  return Producto(
    id: 'p1',
    nombre: 'Producto',
    precio: precio,
    precioOferta: precioOferta,
    existencias: existencias,
    estado: estado,
    creadoPor: 'u1',
    creadoEn: DateTime(2026, 1, 1),
  );
}

void main() {
  group('porcentajeOff', () {
    test('null cuando no hay precio de oferta', () {
      expect(_producto(precioOferta: null).porcentajeOff, isNull);
    });

    test('null cuando el precio de oferta es igual al precio normal', () {
      expect(_producto(precio: 100, precioOferta: 100).porcentajeOff, isNull);
    });

    test('null cuando el precio de oferta es mayor al precio normal', () {
      expect(_producto(precio: 100, precioOferta: 120).porcentajeOff, isNull);
    });

    test('calcula el porcentaje redondeado cuando la oferta es válida', () {
      expect(_producto(precio: 200, precioOferta: 150).porcentajeOff, 25);
      expect(_producto(precio: 100, precioOferta: 33).porcentajeOff, 67);
    });
  });

  group('estaDisponible', () {
    test('true solo si está activo y con stock', () {
      expect(_producto(existencias: 1, estado: EstadoProducto.active).estaDisponible, isTrue);
      expect(_producto(existencias: 0, estado: EstadoProducto.active).estaDisponible, isFalse);
      expect(_producto(existencias: 5, estado: EstadoProducto.inactive).estaDisponible, isFalse);
    });
  });

  group('fromMap/toMap', () {
    test('el estado desconocido de la BD cae en active por defecto', () {
      final producto = Producto.fromMap({
        'id': 'p1',
        'name': 'X',
        'price': 10,
        'status': 'algo_invalido',
      });
      expect(producto.estado, EstadoProducto.active);
      expect(producto.existencias, 0);
    });
  });
}
