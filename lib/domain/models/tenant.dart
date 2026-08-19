class Tenant {
  final String id;
  final String slug;
  final String businessName;
  final String status; // active | suspended | maintenance
  final DateTime creadoEn;
  final List<TenantDomain> dominios;

  const Tenant({
    required this.id,
    required this.slug,
    required this.businessName,
    required this.status,
    required this.creadoEn,
    this.dominios = const [],
  });

  factory Tenant.fromMap(Map<String, dynamic> map) {
    final dominiosData = map['tenant_domains'] as List<dynamic>? ?? [];
    return Tenant(
      id: map['id'] as String,
      slug: map['slug'] as String,
      businessName: map['business_name'] as String,
      status: map['status'] as String? ?? 'active',
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      dominios: dominiosData
          .map((d) => TenantDomain.fromMap(d as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get estaActivo => status == 'active';
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
