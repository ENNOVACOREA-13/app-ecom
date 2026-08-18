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
          'supabase_url': 'https://tenant1.example.com',
          'supabase_anon_key': 'clave-anonima',
          'slug': 'tenant1',
          'business_name': 'Barbería Uno',
          'status': 'active',
        }
      ]);
      expect(resultado.supabaseUrl, 'https://tenant1.example.com');
      expect(resultado.supabaseAnonKey, 'clave-anonima');
      expect(resultado.slug, 'tenant1');
      expect(resultado.status, 'active');
    });

    test('fila con supabase_url vacío o nulo cae al fallback en vez de dejar la app rota', () {
      expect(
        parsearFilasTenant([
          {'supabase_url': '', 'supabase_anon_key': 'clave'}
        ]),
        fallbackTenant,
      );
      expect(
        parsearFilasTenant([
          {'supabase_url': null, 'supabase_anon_key': 'clave'}
        ]),
        fallbackTenant,
      );
    });

    test('fila con supabase_anon_key vacío o nulo cae al fallback', () {
      expect(
        parsearFilasTenant([
          {'supabase_url': 'https://tenant1.example.com', 'supabase_anon_key': ''}
        ]),
        fallbackTenant,
      );
      expect(
        parsearFilasTenant([
          {'supabase_url': 'https://tenant1.example.com', 'supabase_anon_key': null}
        ]),
        fallbackTenant,
      );
    });

    test('solo usa la primera fila si hay más de un match', () {
      final resultado = parsearFilasTenant([
        {'supabase_url': 'https://primero.example.com', 'supabase_anon_key': 'k1'},
        {'supabase_url': 'https://segundo.example.com', 'supabase_anon_key': 'k2'},
      ]);
      expect(resultado.supabaseUrl, 'https://primero.example.com');
    });
  });
}
