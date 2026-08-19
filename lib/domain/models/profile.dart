import '../enums/user_role.dart';

class Perfil {
  final String id;
  final RolUsuario rol;
  final String nombreCompleto;
  final String? telefono;
  final String? urlAvatar;
  final String? bio;
  final bool estaActivo;
  final bool emailVerificado;
  final DateTime creadoEn;
  // Tenant efectivo resuelto por obtener_mi_perfil_efectivo() (dominio +
  // membresía si aplica — ver migración 20260819130000). app_shell.dart lo
  // compara contra kTenantIdActivo (el tenant del dominio visitado) para
  // detectar cuando una cuenta ve "su" tenant de casa en el dominio de OTRO
  // negocio, en vez de confiar en que basta con estar autenticado.
  final String? tenantId;

  const Perfil({
    required this.id,
    required this.rol,
    required this.nombreCompleto,
    this.telefono,
    this.urlAvatar,
    this.bio,
    required this.estaActivo,
    this.emailVerificado = true,
    required this.creadoEn,
    this.tenantId,
  });

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] as String,
      rol: RolUsuario.fromString(map['role'] as String? ?? 'client'),
      nombreCompleto: map['full_name'] as String? ?? '',
      telefono: map['phone'] as String?,
      urlAvatar: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      estaActivo: map['is_active'] as bool? ?? true,
      emailVerificado: map['email_verificado'] as bool? ?? true,
      creadoEn: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      tenantId: map['tenant_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'full_name': nombreCompleto,
        'phone': telefono,
        'avatar_url': urlAvatar,
        'bio': bio,
      };

  Perfil copyWith({
    String? nombreCompleto,
    String? telefono,
    String? urlAvatar,
    String? bio,
    RolUsuario? rol,
    bool? estaActivo,
    bool? emailVerificado,
  }) {
    return Perfil(
      id: id,
      rol: rol ?? this.rol,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      telefono: telefono ?? this.telefono,
      urlAvatar: urlAvatar ?? this.urlAvatar,
      bio: bio ?? this.bio,
      estaActivo: estaActivo ?? this.estaActivo,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      creadoEn: creadoEn,
      tenantId: tenantId,
    );
  }

  /// true si esta cuenta pertenece al dominio que se está visitando ahora.
  /// platform_admin es un caso especial, pero NO un comodín: solo
  /// "pertenece" al dominio SIN tenant (el control plane) — su
  /// profiles.tenant_id es un relleno técnico sin significado (ver
  /// Tenant.fromMap), así que jamás se compara contra un tenant real. Sin
  /// este límite, una sesión de platform_admin restaurada en el navegador
  /// hacía que CUALQUIER dominio de un tenant real (ej. pretty.prettycore.xyz,
  /// el sitio público de ese negocio) mostrara el panel de control en vez
  /// de la interfaz normal de ese negocio — confirmado en vivo 2026-08-19.
  /// Usado tanto en RepositorioAuth.iniciarSesion() (rechaza el login, mismo
  /// mensaje que credenciales inválidas) como en ProveedorAuth._validarTenant
  /// (sesión restaurada/OAuth de otro dominio, cierre de sesión silencioso)
  /// — nunca debe verse distinto de "no hay sesión", o se estaría
  /// confirmando que el correo/contraseña sí existen en otro negocio.
  bool perteneceATenant(String? tenantIdActivo) {
    if (rol == RolUsuario.platformAdmin) return tenantIdActivo == null;
    return tenantId == tenantIdActivo;
  }
}
