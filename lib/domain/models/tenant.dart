class Tenant {
  final String id;
  final String slug;
  final String businessName;
  final String status; // active | suspended | maintenance
  final DateTime creadoEn;
  final List<TenantDomain> dominios;
  final List<CuentaAdminTenant> admins;

  const Tenant({
    required this.id,
    required this.slug,
    required this.businessName,
    required this.status,
    required this.creadoEn,
    this.dominios = const [],
    this.admins = const [],
  });

  factory Tenant.fromMap(
    Map<String, dynamic> map, {
    List<Map<String, dynamic>> membresias = const [],
    Map<String, Map<String, dynamic>> perfilesPorId = const {},
  }) {
    final dominiosData = map['tenant_domains'] as List<dynamic>? ?? [];
    // platform_admin puede aparecer aquí por la cláusula "ver mi propio
    // perfil" de RLS (su tenant_id es solo un relleno técnico, nunca
    // significa que administra este negocio) — se excluye explícitamente
    // en vez de confiar en que el filtro de rol de la policy baste.
    final adminsData = (map['profiles'] as List<dynamic>? ?? [])
        .where((a) => (a as Map<String, dynamic>)['role'] != 'platform_admin')
        .toList();
    final deProfiles = adminsData
        .map((a) => CuentaAdminTenant.fromMap(a as Map<String, dynamic>))
        .toList();
    final id = map['id'] as String;
    // Filtra las membresías a las de ESTE tenant aquí adentro (no confía en
    // que quien llama ya las haya filtrado) — así la función queda
    // autocontenida y fácil de probar con la lista completa.
    final membresiasDeEsteTenant =
        membresias.where((m) => m['tenant_id'] == id).toList();
    return Tenant(
      id: id,
      slug: map['slug'] as String,
      businessName: map['business_name'] as String,
      status: map['status'] as String? ?? 'active',
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      dominios: dominiosData
          .map((d) => TenantDomain.fromMap(d as Map<String, dynamic>))
          .toList(),
      admins: combinarCuentasAdmin(
        deProfiles: deProfiles,
        membresias: membresiasDeEsteTenant,
        perfilesPorId: perfilesPorId,
      ),
    );
  }

  bool get estaActivo => status == 'active';
}

/// Junta los admins "de casa" (profiles.tenant_id fijo) con los que
/// administran este negocio solo por una membresía extra (una misma cuenta
/// puede ser sysadmin de varios negocios — ver migración
/// 20260819130000_multi_tenant_membership.sql). Sin esto, un admin/sysadmin
/// invitado a un SEGUNDO negocio nunca aparecía en el panel de Negocios de
/// ese negocio, porque profiles.tenant_id solo apunta a su negocio "de casa".
/// Si una cuenta tiene ambas (poco común, ej. su propio negocio de casa
/// también tiene una fila de membresía por el backfill), la membresía gana
/// — refleja el mismo criterio que mi_rol_en_tenant_actual() en SQL.
List<CuentaAdminTenant> combinarCuentasAdmin({
  required List<CuentaAdminTenant> deProfiles,
  required List<Map<String, dynamic>> membresias,
  required Map<String, Map<String, dynamic>> perfilesPorId,
}) {
  final porId = {for (final a in deProfiles) a.id: a};
  for (final m in membresias) {
    final idUsuario = m['user_id'] as String;
    final perfil = perfilesPorId[idUsuario];
    porId[idUsuario] = CuentaAdminTenant(
      id: idUsuario,
      rol: m['role'] as String? ?? 'admin',
      nombreCompleto: perfil?['full_name'] as String?,
      email: perfil?['email'] as String?,
    );
  }
  return porId.values.toList();
}

class CuentaAdminTenant {
  final String id;
  final String? nombreCompleto;
  final String? email;
  final String rol;

  const CuentaAdminTenant({
    required this.id,
    required this.rol,
    this.nombreCompleto,
    this.email,
  });

  factory CuentaAdminTenant.fromMap(Map<String, dynamic> map) {
    return CuentaAdminTenant(
      id: map['id'] as String,
      rol: map['role'] as String? ?? 'admin',
      nombreCompleto: map['full_name'] as String?,
      email: map['email'] as String?,
    );
  }
}

class TenantDomain {
  final String id;
  final String tenantId;
  final String domain;
  final DateTime creadoEn;

  const TenantDomain({
    required this.id,
    required this.tenantId,
    required this.domain,
    required this.creadoEn,
  });

  factory TenantDomain.fromMap(Map<String, dynamic> map) {
    return TenantDomain(
      id: map['id'] as String,
      tenantId: map['tenant_id'] as String,
      domain: map['domain'] as String,
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
