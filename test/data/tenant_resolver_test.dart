import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/tenant_resolver.dart';

void main() {
  group('esHostLocalOVacio', () {
    test('localhost, 127.0.0.1 y vacío se consideran locales', () {
      expect(esHostLocalOVacio('localhost'), isTrue);
      expect(esHostLocalOVacio('127.0.0.1'), isTrue);
      expect(esHostLocalOVacio(''), isTrue);
    });

    test('un dominio real de tenant no es local', () {
      expect(esHostLocalOVacio('mc-barber.com'), isFalse);
      expect(esHostLocalOVacio('otro-negocio.sslip.io'), isFalse);
    });
  });

  group('parsearFilasTenant', () {
    test('sin filas cae al fallback', () {
      final resultado = parsearFilasTenant(const []);
      expect(resultado, fallbackTenant);
    });

    test('una fila completa resuelve al tenant correcto', () {
      final resultado = parsearFilasTenant([
        {
          'tenant_id': 'a0000000-0000-0000-0000-000000000001',
          'slug': 'tenant1',
          'business_name': 'Barbería Uno',
          'status': 'active',
        }
      ]);
      expect(resultado.tenantId, 'a0000000-0000-0000-0000-000000000001');
      expect(resultado.slug, 'tenant1');
      expect(resultado.businessName, 'Barbería Uno');
      expect(resultado.status, 'active');
    });

    test('fila con tenant_id vacío o nulo cae al fallback en vez de dejar la app rota', () {
      expect(
        parsearFilasTenant([
          {'tenant_id': ''}
        ]),
        fallbackTenant,
      );
      expect(
        parsearFilasTenant([
          {'tenant_id': null}
        ]),
        fallbackTenant,
      );
    });

    test('solo usa la primera fila si hay más de un match', () {
      final resultado = parsearFilasTenant([
        {'tenant_id': 'a0000000-0000-0000-0000-000000000001', 'slug': 'primero'},
        {'tenant_id': 'b0000000-0000-0000-0000-000000000001', 'slug': 'segundo'},
      ]);
      expect(resultado.tenantId, 'a0000000-0000-0000-0000-000000000001');
      expect(resultado.slug, 'primero');
    });
  });
}
