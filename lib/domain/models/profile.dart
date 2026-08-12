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
    );
  }
}
