import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/saved_provider.dart';
import 'package:prettycore/data/saved_repository.dart';

class MockRepositorioGuardados extends Mock implements RepositorioGuardados {}

void main() {
  group('toggleGuardado', () {
    test('éxito: agrega el producto y el cambio queda firme', () async {
      final repo = MockRepositorioGuardados();
      when(() => repo.obtenerGuardados('u1')).thenAnswer((_) async => []);
      when(() => repo.guardar('u1', 'p1')).thenAnswer((_) async {});

      final provider = ProveedorGuardados(repo: repo);
      await provider.cargar('u1');
      await provider.toggleGuardado('p1');

      expect(provider.estaGuardado('p1'), isTrue);
    });

    test('falla al guardar en el servidor: revierte el cambio optimista', () async {
      final repo = MockRepositorioGuardados();
      when(() => repo.obtenerGuardados('u1')).thenAnswer((_) async => []);
      when(() => repo.guardar('u1', 'p1')).thenThrow(Exception('network error'));

      final provider = ProveedorGuardados(repo: repo);
      await provider.cargar('u1');
      await provider.toggleGuardado('p1');

      expect(provider.estaGuardado('p1'), isFalse,
          reason: 'si el servidor rechaza el guardado, no debe quedar marcado localmente');
    });

    test('falla al quitar en el servidor: el producto vuelve a aparecer como guardado', () async {
      final repo = MockRepositorioGuardados();
      when(() => repo.obtenerGuardados('u1')).thenAnswer((_) async => ['p1']);
      when(() => repo.quitar('u1', 'p1')).thenThrow(Exception('network error'));

      final provider = ProveedorGuardados(repo: repo);
      await provider.cargar('u1');
      expect(provider.estaGuardado('p1'), isTrue);

      await provider.toggleGuardado('p1');

      expect(provider.estaGuardado('p1'), isTrue,
          reason: 'si el servidor rechaza el quitado, debe seguir marcado como guardado');
    });
  });
}
