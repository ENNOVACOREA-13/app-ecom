import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prettycore/providers/tenant_provider.dart';
import 'package:prettycore/data/tenant_repository.dart';
import 'package:prettycore/domain/models/tenant.dart';

class MockRepositorioTenants extends Mock implements RepositorioTenants {}

Tenant _tenant(String id, {String status = 'active', List<TenantDomain> dominios = const []}) =>
    Tenant(
      id: id,
      slug: 'slug-$id',
      businessName: 'Negocio $id',
      status: status,
      creadoEn: DateTime(2026, 1, 1),
      dominios: dominios,
    );

void main() {
  group('cargarTenants', () {
    test('éxito: llena la lista y limpia el error', () async {
      final repo = MockRepositorioTenants();
      when(() => repo.obtenerTenants()).thenAnswer((_) async => [_tenant('a'), _tenant('b')]);

      final provider = ProveedorTenants(repo: repo);
      await provider.cargarTenants();

      expect(provider.tenants.map((t) => t.id), ['a', 'b']);
      expect(provider.error, isNull);
      expect(provider.cargando, isFalse);
    });

    test('falla en el servidor: deja la lista vacía y guarda un error', () async {
      final repo = MockRepositorioTenants();
      when(() => repo.obtenerTenants()).thenThrow(Exception('boom'));

      final provider = ProveedorTenants(repo: repo);
      await provider.cargarTenants();

      expect(provider.tenants, isEmpty);
      expect(provider.error, isNotNull);
    });
  });

  group('crearTenant', () {
    test('éxito: crea y recarga la lista', () async {
      final repo = MockRepositorioTenants();
      when(() => repo.crearTenant(slug: 'nuevo', businessName: 'Nuevo Negocio'))
          .thenAnswer((_) async => _tenant('x'));
      when(() => repo.obtenerTenants()).thenAnswer((_) async => [_tenant('x')]);

      final provider = ProveedorTenants(repo: repo);
      final ok = await provider.crearTenant(slug: 'nuevo', businessName: 'Nuevo Negocio');

      expect(ok, isTrue);
      expect(provider.tenants.map((t) => t.id), ['x']);
      expect(provider.error, isNull);
    });

    test('slug duplicado: expone un mensaje específico, sin el error crudo', () async {
      final repo = MockRepositorioTenants();
      when(() => repo.crearTenant(slug: 'repetido', businessName: 'X'))
          .thenThrow(Exception('duplicate key value violates unique constraint'));

      final provider = ProveedorTenants(repo: repo);
      final ok = await provider.crearTenant(slug: 'repetido', businessName: 'X');

      expect(ok, isFalse);
      expect(provider.error, contains('slug'));
    });
  });

  group('actualizarStatus', () {
    test('éxito: actualiza y recarga la lista', () async {
      final repo = MockRepositorioTenants();
      when(() => repo.actualizarStatus('a', 'suspended')).thenAnswer((_) async {});
      when(() => repo.obtenerTenants()).thenAnswer((_) async => [_tenant('a', status: 'suspended')]);

      final provider = ProveedorTenants(repo: repo);
      final ok = await provider.actualizarStatus('a', 'suspended');

      expect(ok, isTrue);
      expect(provider.tenants.first.status, 'suspended');
    });
  });

  group('agregarDominio', () {
    test('éxito: agrega y recarga la lista', () async {
      final repo = MockRepositorioTenants();
      final dominio = TenantDomain(
          id: 'd1', tenantId: 'a', domain: 'mi-negocio.vercel.app', creadoEn: DateTime(2026, 1, 1));
      when(() => repo.agregarDominio('a', 'mi-negocio.vercel.app')).thenAnswer((_) async => dominio);
      when(() => repo.obtenerTenants())
          .thenAnswer((_) async => [_tenant('a', dominios: [dominio])]);

      final provider = ProveedorTenants(repo: repo);
      final ok = await provider.agregarDominio('a', 'mi-negocio.vercel.app');

      expect(ok, isTrue);
      expect(provider.tenants.first.dominios.single.domain, 'mi-negocio.vercel.app');
    });

    test('dominio duplicado: expone un mensaje específico', () async {
      final repo = MockRepositorioTenants();
      when(() => repo.agregarDominio('a', 'repetido.com'))
          .thenThrow(Exception('duplicate key value violates unique constraint'));

      final provider = ProveedorTenants(repo: repo);
      final ok = await provider.agregarDominio('a', 'repetido.com');

      expect(ok, isFalse);
      expect(provider.error, contains('dominio'));
    });
  });

  group('eliminarDominio', () {
    test('éxito: elimina y recarga la lista', () async {
      final repo = MockRepositorioTenants();
      when(() => repo.eliminarDominio('d1')).thenAnswer((_) async {});
      when(() => repo.obtenerTenants()).thenAnswer((_) async => [_tenant('a')]);

      final provider = ProveedorTenants(repo: repo);
      final ok = await provider.eliminarDominio('d1');

      expect(ok, isTrue);
      expect(provider.tenants.first.dominios, isEmpty);
    });
  });
}
