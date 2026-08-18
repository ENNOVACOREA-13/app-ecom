import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/product_provider.dart';
import 'package:prettycore/data/product_repository.dart';
import 'package:prettycore/domain/models/product.dart';
import 'package:prettycore/domain/enums/product_status.dart';

class MockRepositorioProducto extends Mock implements RepositorioProducto {}

Producto _producto({String id = 'p1'}) => Producto(
      id: id,
      nombre: 'Cera',
      precio: 50,
      existencias: 10,
      estado: EstadoProducto.active,
      creadoPor: 'u1',
      creadoEn: DateTime(2026, 1, 1),
    );

void main() {
  group('cargarProductos', () {
    test('éxito: reemplaza la lista y limpia el error', () async {
      final repo = MockRepositorioProducto();
      when(() => repo.obtenerProductosActivos()).thenAnswer((_) async => [_producto()]);

      final provider = ProveedorProducto(repo: repo);
      await provider.cargarProductos();

      expect(provider.productos.length, 1);
      expect(provider.error, isNull);
      expect(provider.cargando, isFalse);
    });

    test('vista admin pide obtenerTodosLosProductos, no obtenerProductosActivos', () async {
      final repo = MockRepositorioProducto();
      when(() => repo.obtenerTodosLosProductos()).thenAnswer((_) async => [_producto()]);

      final provider = ProveedorProducto(repo: repo);
      await provider.cargarProductos(esVistaAdmin: true);

      verify(() => repo.obtenerTodosLosProductos()).called(1);
      verifyNever(() => repo.obtenerProductosActivos());
    });

    test('falla de red: el error queda mapeado, no crudo', () async {
      final repo = MockRepositorioProducto();
      when(() => repo.obtenerProductosActivos()).thenThrow(Exception('SocketException: fallo'));

      final provider = ProveedorProducto(repo: repo);
      await provider.cargarProductos();

      expect(provider.error, 'Sin conexión a internet.');
      expect(provider.productos, isEmpty);
    });
  });

  group('crearProducto', () {
    test('éxito: inserta al inicio de la lista (más reciente primero)', () async {
      final repo = MockRepositorioProducto();
      when(() => repo.crearProducto(
            nombre: any(named: 'nombre'),
            descripcion: any(named: 'descripcion'),
            precio: any(named: 'precio'),
            precioOferta: any(named: 'precioOferta'),
            existencias: any(named: 'existencias'),
            creadoPor: any(named: 'creadoPor'),
            urlImagen: any(named: 'urlImagen'),
          )).thenAnswer((_) async => _producto(id: 'nuevo'));

      final provider = ProveedorProducto(repo: repo);
      final ok = await provider.crearProducto(
        nombre: 'Cera',
        precio: 50,
        existencias: 10,
        creadoPor: 'u1',
      );

      expect(ok, isTrue);
      expect(provider.productos.first.id, 'nuevo');
    });

    test('sin permiso (RLS): no agrega nada y expone el mensaje mapeado', () async {
      final repo = MockRepositorioProducto();
      when(() => repo.crearProducto(
            nombre: any(named: 'nombre'),
            descripcion: any(named: 'descripcion'),
            precio: any(named: 'precio'),
            precioOferta: any(named: 'precioOferta'),
            existencias: any(named: 'existencias'),
            creadoPor: any(named: 'creadoPor'),
            urlImagen: any(named: 'urlImagen'),
          )).thenThrow(Exception('new row violates row-level security policy'));

      final provider = ProveedorProducto(repo: repo);
      final ok = await provider.crearProducto(
        nombre: 'Cera',
        precio: 50,
        existencias: 10,
        creadoPor: 'u1',
      );

      expect(ok, isFalse);
      expect(provider.productos, isEmpty);
      expect(provider.error, 'No tienes permiso para realizar esta acción.');
    });
  });

  group('eliminarProducto', () {
    test('lo quita de la lista local tras eliminarlo en el servidor', () async {
      final repo = MockRepositorioProducto();
      when(() => repo.obtenerProductosActivos()).thenAnswer((_) async => [_producto(id: 'a'), _producto(id: 'b')]);
      when(() => repo.eliminarProducto('a')).thenAnswer((_) async {});

      final provider = ProveedorProducto(repo: repo);
      await provider.cargarProductos();
      await provider.eliminarProducto('a');

      expect(provider.productos.map((p) => p.id), ['b']);
    });
  });
}
