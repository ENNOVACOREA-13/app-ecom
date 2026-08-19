import 'package:flutter_test/flutter_test.dart';
import 'package:prettycore/data/activity_service.dart';
import 'package:prettycore/data/product_repository.dart';
import 'package:prettycore/data/product_category_repository.dart';
import 'package:prettycore/data/saved_repository.dart';
import 'package:prettycore/data/service_repository.dart';
import 'package:prettycore/domain/models/service_model.dart';
import 'package:prettycore/ui/admin/insumos_page.dart';

// Cubre el bug encontrado 2026-08-19: varios .insert() a tablas
// multi-tenant nunca mandaban tenant_id, y RLS los rechazaba en silencio
// ("violates row-level security policy") o con un error genérico de
// permisos. Cada builder de payload se prueba aparte (sin mockear
// Supabase) para que si alguien vuelve a olvidar tenant_id, un test
// puro lo detecte antes de llegar a producción.
void main() {
  group('construirPayloadProducto', () {
    test('incluye tenant_id', () {
      final payload = construirPayloadProducto(
        tenantId: 'tenant-1',
        nombre: 'Cera',
        precio: 130,
        existencias: 20,
        creadoPor: 'user-1',
      );
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['name'], 'Cera');
    });

    test('tenant_id null se manda tal cual (para que RLS lo rechace, no se pierda en silencio)', () {
      final payload = construirPayloadProducto(
        tenantId: null,
        nombre: 'Cera',
        precio: 130,
        existencias: 20,
        creadoPor: 'user-1',
      );
      expect(payload.containsKey('tenant_id'), isTrue);
      expect(payload['tenant_id'], isNull);
    });
  });

  group('construirPayloadCategoria', () {
    test('incluye tenant_id', () {
      final payload = construirPayloadCategoria(
        tenantId: 'tenant-1',
        nombre: 'Cortes',
        icono: 'content_cut',
      );
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['name'], 'Cortes');
    });
  });

  group('construirPayloadGuardado', () {
    test('incluye tenant_id', () {
      final payload = construirPayloadGuardado(
        tenantId: 'tenant-1',
        userId: 'user-1',
        productId: 'prod-1',
      );
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['user_id'], 'user-1');
      expect(payload['product_id'], 'prod-1');
    });
  });

  group('construirPayloadServicio', () {
    test('incluye tenant_id junto con los campos del modelo', () {
      const servicio = ModeloServicio(
        id: 'serv-1',
        nombre: 'Corte',
        duracionMin: 30,
        precio: 150,
        estaActivo: true,
      );
      final payload = construirPayloadServicio(tenantId: 'tenant-1', servicio: servicio);
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['name'], 'Corte');
      expect(payload['price'], 150);
    });
  });

  group('construirPayloadCrearInsumo', () {
    test('incluye tenant_id', () {
      final payload = construirPayloadCrearInsumo(
        tenantId: 'tenant-1',
        creadoPor: 'user-1',
        nombre: 'Shampoo',
        cantidad: 10,
        precio: 50,
        unidad: 'unidad',
      );
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['created_by'], 'user-1');
      expect(payload['name'], 'Shampoo');
    });
  });

  group('construirPayloadSesion', () {
    test('incluye tenant_id', () {
      final payload = construirPayloadSesion(
        tenantId: 'tenant-1',
        profileId: 'user-1',
        platform: 'web',
        device: 'Web Browser',
      );
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['profile_id'], 'user-1');
    });
  });

  group('construirPayloadActividad', () {
    test('incluye tenant_id', () {
      final payload = construirPayloadActividad(
        tenantId: 'tenant-1',
        profileId: 'user-1',
        sessionId: 'sesion-1',
        eventType: 'screen_view',
        eventName: 'Home',
      );
      expect(payload['tenant_id'], 'tenant-1');
      expect(payload['event_type'], 'screen_view');
    });

    test('extra opcional solo se incluye si se manda', () {
      final sinExtra = construirPayloadActividad(
        tenantId: 'tenant-1',
        profileId: 'user-1',
        eventType: 'tap',
        eventName: 'boton',
      );
      expect(sinExtra.containsKey('extra'), isFalse);

      final conExtra = construirPayloadActividad(
        tenantId: 'tenant-1',
        profileId: 'user-1',
        eventType: 'tap',
        eventName: 'boton',
        extra: {'x': 1},
      );
      expect(conExtra['extra'], {'x': 1});
    });
  });
}
