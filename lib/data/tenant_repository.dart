import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/tenant.dart';
import 'user_provisioning_service.dart';

/// Traduce los códigos de error de admin-delete-tenant a un mensaje legible.
String mapearErrorBorradoTenant(String e) {
  final codigo = e.replaceFirst('Exception: ', '').trim();
  switch (codigo) {
    case 'slug_mismatch':
      return 'El slug no coincide. Escríbelo exactamente para confirmar.';
    case 'contains_principal_sysadmin':
      return 'No se puede eliminar: este negocio tiene la cuenta sysadmin principal de la plataforma.';
    case 'contains_platform_admin':
      return 'No se puede eliminar: este negocio tiene una cuenta de administrador de la plataforma ligada.';
    case 'tenant_not_found':
      return 'Ese negocio ya no existe.';
    case 'forbidden':
      return 'No tienes permiso para eliminar negocios.';
    case 'missing_auth':
    case 'invalid_session':
      return 'Tu sesión no tiene permiso para hacer esto.';
    default:
      return 'No se pudo eliminar el negocio.';
  }
}

class RepositorioTenants {
  SupabaseClient get _client => Supabase.instance.client;
  final ServicioAltaUsuarios _servicioAlta = ServicioAltaUsuarios();

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

  /// Elimina por completo la cuenta "de casa" de un admin/super_admin de un
  /// negocio — perfil Y cuenta de Supabase Auth (vía Edge Function
  /// admin-delete-user), para que el correo quede libre para un registro
  /// nuevo en vez de dejar una sesión de Auth "colgada" sin perfil. Las
  /// cuentas sysadmin nunca se pueden eliminar (bloqueado también por
  /// trigger a nivel de base de datos).
  Future<void> eliminarPerfilAdmin(String userId) async {
    await _servicioAlta.eliminarUsuario(userId);
  }

  /// Elimina un negocio por completo e irreversiblemente — vía Edge Function
  /// admin-delete-tenant, que borra en cascada TODO lo que le pertenece
  /// (reservas, pedidos, productos, comisiones, perfiles y cuentas de Auth
  /// de sus clientes/empleados/admins) y exige el slug exacto como
  /// confirmación server-side, no solo en el diálogo de la UI. Rechaza
  /// borrar cualquier negocio que sea "de casa" del sysadmin principal de
  /// la plataforma.
  Future<void> eliminarTenant({
    required String tenantId,
    required String slugConfirmacion,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('missing_session');

    final respuesta = await http.post(
      Uri.parse('$kSupabaseUrl/functions/v1/admin-delete-tenant'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'tenant_id': tenantId, 'slug_confirmacion': slugConfirmacion}),
    );

    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    if (cuerpo['success'] != true) {
      throw Exception(cuerpo['error'] ?? 'unknown_error');
    }
  }
}
