import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/tenant.dart';

class RepositorioTenants {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Tenant>> obtenerTenants() async {
    final datos = await _client
        .from('tenants')
        .select('*, tenant_domains(*)')
        .order('created_at');
    return (datos as List)
        .map((e) => Tenant.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<Tenant> crearTenant({required String slug, required String businessName}) async {
    final datos = await _client
        .from('tenants')
        .insert({'slug': slug, 'business_name': businessName})
        .select('*, tenant_domains(*)')
        .single();
    return Tenant.fromMap(datos);
  }

  Future<void> actualizarStatus(String tenantId, String status) async {
    await _client.from('tenants').update({'status': status}).eq('id', tenantId);
  }

  Future<TenantDomain> agregarDominio(String tenantId, String domain) async {
    final datos = await _client
        .from('tenant_domains')
        .insert({'tenant_id': tenantId, 'domain': domain})
        .select()
        .single();
    return TenantDomain.fromMap(datos);
  }

  Future<void> eliminarDominio(String domainId) async {
    await _client.from('tenant_domains').delete().eq('id', domainId);
  }
}
