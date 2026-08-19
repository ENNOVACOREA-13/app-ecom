import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/product_category.dart';

/// Ver construirPayloadProducto() en product_repository.dart — mismo motivo.
Map<String, dynamic> construirPayloadCategoria({
  required String? tenantId,
  required String nombre,
  required String icono,
  String? imagenUrl,
}) {
  return {'tenant_id': tenantId, 'name': nombre, 'icon': icono, 'image_url': imagenUrl};
}

class RepositorioCategoriasProducto {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CategoriaProducto>> obtenerCategorias() async {
    final datos = await _client
        .from('product_categories')
        .select()
        .order('sort_order');
    return (datos as List)
        .map((e) => CategoriaProducto.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> crearCategoria(
      {required String nombre, required String icono, String? imagenUrl}) async {
    await _client.from('product_categories').insert(construirPayloadCategoria(
        tenantId: kTenantIdActivo, nombre: nombre, icono: icono, imagenUrl: imagenUrl));
  }

  Future<void> actualizarCategoria(String id,
      {required String nombre, required String icono, String? imagenUrl}) async {
    await _client
        .from('product_categories')
        .update({'name': nombre, 'icon': icono, 'image_url': imagenUrl}).eq('id', id);
  }

  Future<void> eliminarCategoria(String id) async {
    await _client.from('product_categories').delete().eq('id', id);
  }

  Future<void> reordenarCategorias(List<String> idsEnOrden) async {
    for (int i = 0; i < idsEnOrden.length; i++) {
      await _client
          .from('product_categories')
          .update({'sort_order': i}).eq('id', idsEnOrden[i]);
    }
  }
}
