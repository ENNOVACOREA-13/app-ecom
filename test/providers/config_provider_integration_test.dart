import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/config_provider.dart';
import 'package:prettycore/data/config_repository.dart';

class MockRepositorioConfig extends Mock implements RepositorioConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('actualizarTiendaHabilitada', () {
    test('éxito: refleja el nuevo valor local', () async {
      final repo = MockRepositorioConfig();
      when(() => repo.actualizarTiendaHabilitada(false)).thenAnswer((_) async => true);

      final provider = ProveedorConfig(repo: repo);
      final ok = await provider.actualizarTiendaHabilitada(false);

      expect(ok, isTrue);
      expect(provider.tiendaHabilitada, isFalse);
    });

    test('falla en el servidor: NO cambia el valor local (evita mostrar algo que no se guardó)', () async {
      final repo = MockRepositorioConfig();
      when(() => repo.actualizarTiendaHabilitada(false)).thenAnswer((_) async => false);

      final provider = ProveedorConfig(repo: repo);
      final valorInicial = provider.tiendaHabilitada;
      final ok = await provider.actualizarTiendaHabilitada(false);

      expect(ok, isFalse);
      expect(provider.tiendaHabilitada, valorInicial);
    });
  });

  group('publicarBorrador', () {
    test('éxito: copia el borrador a los valores en vivo y limpia tieneBorrador', () async {
      final repo = MockRepositorioConfig();
      when(() => repo.guardarBorrador(any())).thenAnswer((_) async => true);
      when(() => repo.publicarBorrador(any())).thenAnswer((_) async => true);

      final provider = ProveedorConfig(repo: repo);
      await provider.actualizarBorradorProductos('Nuevo título');
      final ok = await provider.publicarBorrador();

      expect(ok, isTrue);
      expect(provider.productosTitulo, 'Nuevo título');
      expect(provider.tieneBorrador, isFalse);
    });

    test('falla en el servidor: el borrador sigue pendiente, no se pierde', () async {
      final repo = MockRepositorioConfig();
      when(() => repo.guardarBorrador(any())).thenAnswer((_) async => true);
      when(() => repo.publicarBorrador(any())).thenAnswer((_) async => false);

      final provider = ProveedorConfig(repo: repo);
      await provider.actualizarBorradorProductos('Nuevo título');
      final ok = await provider.publicarBorrador();

      expect(ok, isFalse);
      expect(provider.productosTituloBorrador, 'Nuevo título',
          reason: 'el borrador no se descarta solo porque publicar falló');
      expect(provider.productosTitulo, isNot('Nuevo título'),
          reason: 'lo publicado no debe cambiar si el publish falló');
    });
  });

  group('descartarBorrador', () {
    test('éxito: el borrador vuelve a igualar los valores en vivo', () async {
      final repo = MockRepositorioConfig();
      when(() => repo.guardarBorrador(any())).thenAnswer((_) async => true);
      when(() => repo.descartarBorrador()).thenAnswer((_) async => true);

      final provider = ProveedorConfig(repo: repo);
      await provider.actualizarBorradorProductos('Borrador que se va a tirar');
      final ok = await provider.descartarBorrador();

      expect(ok, isTrue);
      expect(provider.productosTituloBorrador, provider.productosTitulo);
      expect(provider.tieneBorrador, isFalse);
    });
  });
}
