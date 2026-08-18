import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/providers/cart_provider.dart';
import 'package:prettycore/domain/models/product.dart';
import 'package:prettycore/domain/enums/product_status.dart';

Producto _producto({String id = 'p1', double precio = 100, int existencias = 5}) {
  return Producto(
    id: id,
    nombre: 'Producto $id',
    precio: precio,
    existencias: existencias,
    estado: EstadoProducto.active,
    creadoPor: 'u1',
    creadoEn: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ItemCarrito.subtotal', () {
    test('es precio * cantidad', () {
      final item = ItemCarrito(producto: _producto(precio: 50), cantidad: 3);
      expect(item.subtotal, 150);
    });
  });

  group('ProveedorCarrito', () {
    test('total y totalItems empiezan en 0 con carrito vacío', () {
      final carrito = ProveedorCarrito();
      expect(carrito.total, 0);
      expect(carrito.totalItems, 0);
      expect(carrito.vacio, isTrue);
    });

    test('total suma los subtotales de todos los items', () {
      final carrito = ProveedorCarrito();
      carrito.agregar(_producto(id: 'p1', precio: 100), cantidad: 2);
      carrito.agregar(_producto(id: 'p2', precio: 30), cantidad: 1);
      expect(carrito.total, 230);
      expect(carrito.totalItems, 3);
    });

    test('agregar no supera el stock disponible aunque se pida de más', () {
      final carrito = ProveedorCarrito();
      final producto = _producto(existencias: 3);
      carrito.agregar(producto, cantidad: 2);
      carrito.agregar(producto, cantidad: 5); // pide 5 más, solo cabe 1
      expect(carrito.cantidadProducto(producto.id), 3,
          reason: 'la cantidad en el carrito nunca debe superar el stock');
    });

    test('agregar el mismo producto acumula cantidad en un solo item', () {
      final carrito = ProveedorCarrito();
      final producto = _producto(existencias: 10);
      carrito.agregar(producto, cantidad: 2);
      carrito.agregar(producto, cantidad: 3);
      expect(carrito.items.length, 1);
      expect(carrito.cantidadProducto(producto.id), 5);
    });

    test('agregar con stock ya en el máximo devuelve false y no agrega', () {
      final carrito = ProveedorCarrito();
      final producto = _producto(existencias: 2);
      carrito.agregar(producto, cantidad: 2);
      final resultado = carrito.agregar(producto, cantidad: 1);
      expect(resultado, isFalse);
      expect(carrito.cantidadProducto(producto.id), 2);
    });

    test('decrementar reduce cantidad y elimina el item al llegar a 0', () {
      final carrito = ProveedorCarrito();
      final producto = _producto(existencias: 5);
      carrito.agregar(producto, cantidad: 2);
      carrito.decrementar(producto.id);
      expect(carrito.cantidadProducto(producto.id), 1);
      carrito.decrementar(producto.id);
      expect(carrito.contiene(producto.id), isFalse);
    });

    test('quitar elimina el item sin importar la cantidad', () {
      final carrito = ProveedorCarrito();
      final producto = _producto(existencias: 5);
      carrito.agregar(producto, cantidad: 4);
      carrito.quitar(producto.id);
      expect(carrito.contiene(producto.id), isFalse);
      expect(carrito.total, 0);
    });

    test('limpiar vacía el carrito por completo', () {
      final carrito = ProveedorCarrito();
      carrito.agregar(_producto(id: 'p1'), cantidad: 1);
      carrito.agregar(_producto(id: 'p2'), cantidad: 1);
      carrito.limpiar();
      expect(carrito.vacio, isTrue);
    });
  });
}
