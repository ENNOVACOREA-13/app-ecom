import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/tenant.dart';

class RepositorioTenants {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Tenant>> obtenerTenants() async {
    final datos = await _client
        .from('tenants')
        .select('*, tenant_domains(*), profiles(id, full_name, email, role, phone)')
        .order('created_at');

    // user_tenant_memberships no tiene una FK directa a profiles (ambas
    // apuntan a auth.users por separado), así que no se puede embeber en la
    // misma consulta — se pide aparte y se junta en el cliente.
    final membresias = await _client
        .from('user_tenant_memberships')
        .select('tenant_id, user_id, role') as List;
    final idsUsuarios =
        membresias.map((m) => m['user_id'] as String).toSet().toList();
    final perfiles = idsUsuarios.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
            .from('profiles')
            .select('id, full_name, email, role, tenant_id, phone')
            .inFilter('id', idsUsuarios) as List;
    final perfilesPorId = {
      for (final p in perfiles) (p as Map<String, dynamic>)['id'] as String: p
    };

    final membresiasTipadas = membresias.cast<Map<String, dynamic>>();
    return (datos as List)
        .map((e) => Tenant.fromMap(e as Map<String, dynamic>,
            membresias: membresiasTipadas, perfilesPorId: perfilesPorId))
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

  /// Quita el acceso de una cuenta a ESTE tenant vía membresía (no borra la
  /// cuenta ni su acceso a su tenant "de casa" — solo esta fila extra).
  Future<void> eliminarMembresia({required String userId, required String tenantId}) async {
    await _client
        .from('user_tenant_memberships')
        .delete()
        .eq('user_id', userId)
        .eq('tenant_id', tenantId);
  }

  /// Edita nombre/teléfono de una cuenta admin/sysadmin de cualquier
  /// negocio (RLS: profiles_update_platform_admin). No toca el rol ni el
  /// email — un trigger bloquea cualquier intento de cambiar el rol del
  /// sysadmin principal de la plataforma.
  Future<void> editarPerfilAdmin({
    required String userId,
    required String nombre,
    String? telefono,
  }) async {
    await _client.from('profiles').update({
      'full_name': nombre,
      'phone': telefono,
    }).eq('id', userId);
  }

  /// Elimina por completo el perfil "de casa" de un admin/super_admin de un
  /// negocio (RLS: profiles_delete_platform_admin). Las cuentas sysadmin
  /// nunca se pueden eliminar (bloqueado por trigger a nivel de base de
  /// datos, no solo aquí).
  Future<void> eliminarPerfilAdmin(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }
}
