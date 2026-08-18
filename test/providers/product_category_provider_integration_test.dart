import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/product_category_provider.dart';
import 'package:prettycore/data/product_category_repository.dart';
import 'package:prettycore/domain/models/product_category.dart';

class MockRepositorioCategoriasProducto extends Mock implements RepositorioCategoriasProducto {}

CategoriaProducto _categoria(String id, int orden) =>
    CategoriaProducto(id: id, nombre: 'Cat $id', icono: 'category', orden: orden);

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  group('eliminarCategoria', () {
    test('éxito: la quita de la lista local', () async {
      final repo = MockRepositorioCategoriasProducto();
      when(() => repo.obtenerCategorias())
          .thenAnswer((_) async => [_categoria('a', 0), _categoria('b', 1)]);
      when(() => repo.eliminarCategoria('a')).thenAnswer((_) async {});

      final provider = ProveedorCategoriasProducto(repo: repo);
      await provider.cargarCategorias();
      final ok = await provider.eliminarCategoria('a');

      expect(ok, isTrue);
      expect(provider.categorias.map((c) => c.id), ['b']);
    });

    test('falla en el servidor: no la quita de la lista local', () async {
      final repo = MockRepositorioCategoriasProducto();
      when(() => repo.obtenerCategorias()).thenAnswer((_) async => [_categoria('a', 0)]);
      when(() => repo.eliminarCategoria('a')).thenThrow(Exception('boom'));

      final provider = ProveedorCategoriasProducto(repo: repo);
      await provider.cargarCategorias();
      final ok = await provider.eliminarCategoria('a');

      expect(ok, isFalse);
      expect(provider.categorias.map((c) => c.id), ['a']);
    });
  });

  group('reordenarCategorias', () {
    test('actualiza el orden local de inmediato (optimista) y avisa al servidor', () async {
      final repo = MockRepositorioCategoriasProducto();
      when(() => repo.reordenarCategorias(['b', 'a'])).thenAnswer((_) async {});

      final provider = ProveedorCategoriasProducto(repo: repo);
      await provider.reordenarCategorias([_categoria('b', 0), _categoria('a', 1)]);

      expect(provider.categorias.map((c) => c.id), ['b', 'a']);
      verify(() => repo.reordenarCategorias(['b', 'a'])).called(1);
    });
  });
}
