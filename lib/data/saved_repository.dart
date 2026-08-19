import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class RepositorioGuardados {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<String>> obtenerGuardados(String userId) async {
    final data = await _client
        .from('saved_products')
        .select('product_id')
        .eq('user_id', userId);
    return (data as List).map((e) => e['product_id'] as String).toList();
  }

  Future<void> guardar(String userId, String productId) async {
    await _client.from('saved_products').insert({
      'tenant_id': kTenantIdActivo,
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<void> quitar(String userId, String productId) async {
    await _client
        .from('saved_products')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
