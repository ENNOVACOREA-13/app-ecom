import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/product.dart';

/// Separado de crearProducto() para poder probar en un test puro (sin
/// mockear Supabase) que el payload siempre incluye tenant_id — el tipo
/// de bug que rompió la creación de productos en silencio (RLS lo
/// rechazaba con "violates row-level security policy").
Map<String, dynamic> construirPayloadProducto({
  required String? tenantId,
  required String nombre,
  String? descripcion,
  required double precio,
  double? precioOferta,
  required int existencias,
  required String creadoPor,
  String? urlImagen,
}) {
  return {
    'tenant_id': tenantId,
    'name': nombre,
    'description': descripcion,
    'price': precio,
    'sale_price': precioOferta,
    'stock': existencias,
    'created_by': creadoPor,
    'image_url': urlImagen,
    'status': 'active',
  };
}

class RepositorioProducto {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Producto>> obtenerProductosActivos() async {
    final datos = await _client
        .from('products')
        .select()
        .eq('status', 'active')
        .order('name');
    return (datos as List).map((e) => Producto.fromMap(e)).toList();
  }

  Future<List<Producto>> obtenerTodosLosProductos() async {
    final datos = await _client
        .from('products')
        .select()
        .neq('status', 'inactive')
        .order('created_at', ascending: false);
    return (datos as List).map((e) => Producto.fromMap(e)).toList();
  }

  Future<Producto> crearProducto({
    required String nombre,
    String? descripcion,
    required double precio,
    double? precioOferta,
    required int existencias,
    required String creadoPor,
    String? urlImagen,
  }) async {
    final datos = await _client
        .from('products')
        .insert(construirPayloadProducto(
          tenantId: kTenantIdActivo,
          nombre: nombre,
          descripcion: descripcion,
          precio: precio,
          precioOferta: precioOferta,
          existencias: existencias,
          creadoPor: creadoPor,
          urlImagen: urlImagen,
        ))
        .select()
        .single();
    return Producto.fromMap(datos);
  }

  Future<void> actualizarProducto(String id, Map<String, dynamic> actualizaciones) async {
    await _client.from('products').update(actualizaciones).eq('id', id);
  }

  Future<void> eliminarProducto(String id) async {
    await _client.from('products').update({'status': 'inactive'}).eq('id', id);
  }

  Future<String> subirImagenProducto(String idProducto, Uint8List bytes, String formato) async {
    final ruta = '$kTenantIdActivo/$idProducto.$formato';
    await _client.storage.from('media').uploadBinary(
      ruta,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: 'image/$formato'),
    );
    return _client.storage.from('media').getPublicUrl(ruta);
  }
}
