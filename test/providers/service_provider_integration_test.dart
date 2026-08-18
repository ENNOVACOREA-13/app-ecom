import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/service_provider.dart';
import 'package:prettycore/data/service_repository.dart';
import 'package:prettycore/domain/models/service_model.dart';

class MockRepositorioServicio extends Mock implements RepositorioServicio {}

class FakeModeloServicio extends Fake implements ModeloServicio {}

ModeloServicio _servicio({String id = 's1', double precio = 100}) => ModeloServicio(
      id: id,
      nombre: 'Corte',
      duracionMin: 30,
      precio: precio,
      estaActivo: true,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FakeModeloServicio());
  });

  group('crearServicio', () {
    test('éxito: lo agrega al inicio de la lista', () async {
      final repo = MockRepositorioServicio();
      when(() => repo.crearServicio(any())).thenAnswer((_) async => _servicio(id: 'nuevo'));

      final provider = ProveedorServicio(repo: repo);
      final ok = await provider.crearServicio(_servicio());

      expect(ok, isTrue);
      expect(provider.servicios.first.id, 'nuevo');
    });

    test('falla: no agrega nada y guarda el error', () async {
      final repo = MockRepositorioServicio();
      when(() => repo.crearServicio(any())).thenThrow(Exception('boom'));

      final provider = ProveedorServicio(repo: repo);
      final ok = await provider.crearServicio(_servicio());

      expect(ok, isFalse);
      expect(provider.servicios, isEmpty);
      expect(provider.error, isNotNull);
    });
  });

  group('actualizarServicio', () {
    test('actualiza en el servidor y refleja el cambio localmente sin recargar todo', () async {
      final repo = MockRepositorioServicio();
      when(() => repo.obtenerServiciosActivos()).thenAnswer((_) async => [_servicio(id: 's1', precio: 100)]);
      when(() => repo.actualizarServicio('s1', {'price': 150})).thenAnswer((_) async {});

      final provider = ProveedorServicio(repo: repo);
      await provider.cargarServicios();
      await provider.actualizarServicio('s1', {'price': 150});

      expect(provider.servicios.first.precio, 150);
      verify(() => repo.actualizarServicio('s1', {'price': 150})).called(1);
    });
  });

  group('eliminarServicio', () {
    test('lo quita de la lista local', () async {
      final repo = MockRepositorioServicio();
      when(() => repo.obtenerServiciosActivos())
          .thenAnswer((_) async => [_servicio(id: 'a'), _servicio(id: 'b')]);
      when(() => repo.eliminarServicio('a')).thenAnswer((_) async {});

      final provider = ProveedorServicio(repo: repo);
      await provider.cargarServicios();
      await provider.eliminarServicio('a');

      expect(provider.servicios.map((s) => s.id), ['b']);
    });
  });
}
