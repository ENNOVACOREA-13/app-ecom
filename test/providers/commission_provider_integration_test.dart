import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/commission_provider.dart';
import 'package:prettycore/data/commission_repository.dart';
import 'package:prettycore/domain/models/commission_model.dart';

class MockRepositorioComision extends Mock implements RepositorioComision {}

CorteComision _corte({String id = 'c1', String estado = 'pending'}) => CorteComision(
      id: id,
      empleadoId: 'e1',
      inicioSemana: DateTime(2026, 8, 10),
      finSemana: DateTime(2026, 8, 16),
      montoTotal: 500,
      cantidadServicios: 5,
      estado: estado,
      creadoEl: DateTime(2026, 8, 17),
    );

void main() {
  group('guardarConfiguracion', () {
    test('editando una configuración existente, la actualiza en memoria sin recargar todo', () async {
      final repo = MockRepositorioComision();
      when(() => repo.guardarConfiguracion('s1', 60)).thenAnswer((_) async {});

      final provider = ProveedorComision(repo: repo)
        ..configuraciones = [const ConfigComision(id: 'cfg1', servicioId: 's1', monto: 40)];

      await provider.guardarConfiguracion('s1', 60);

      expect(provider.montoPorServicio('s1'), 60);
      verifyNever(() => repo.obtenerConfiguraciones());
    });

    test('un servicio sin configuración previa recarga la lista completa del servidor', () async {
      final repo = MockRepositorioComision();
      when(() => repo.guardarConfiguracion('s2', 30)).thenAnswer((_) async {});
      when(() => repo.obtenerConfiguraciones())
          .thenAnswer((_) async => [const ConfigComision(id: 'cfg2', servicioId: 's2', monto: 30)]);

      final provider = ProveedorComision(repo: repo);
      await provider.guardarConfiguracion('s2', 30);

      expect(provider.montoPorServicio('s2'), 30);
      verify(() => repo.obtenerConfiguraciones()).called(1);
    });
  });

  group('marcarCortePagado', () {
    test('actualiza el estado del corte a paid en memoria', () async {
      final repo = MockRepositorioComision();
      when(() => repo.marcarCortePagado('c1', notas: null)).thenAnswer((_) async {});

      final provider = ProveedorComision(repo: repo)..cortes = [_corte(id: 'c1', estado: 'pending')];

      await provider.marcarCortePagado('c1');

      expect(provider.cortes.first.estaPagado, isTrue);
    });
  });

  group('cargarPendientesEmpleado', () {
    test('carga entradas y cortes en paralelo', () async {
      final repo = MockRepositorioComision();
      when(() => repo.obtenerEntradasPendientes('e1')).thenAnswer((_) async => []);
      when(() => repo.obtenerCortesEmpleado('e1')).thenAnswer((_) async => [_corte()]);

      final provider = ProveedorComision(repo: repo);
      await provider.cargarPendientesEmpleado('e1');

      expect(provider.cortes.length, 1);
      expect(provider.cargando, isFalse);
    });
  });
}
