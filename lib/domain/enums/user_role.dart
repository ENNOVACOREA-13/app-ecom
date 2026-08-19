enum RolUsuario {
  client,
  employee,
  admin,
  superAdmin,
  sysadmin,
  platformAdmin;

  static RolUsuario fromString(String value) {
    switch (value) {
      case 'employee':
        return RolUsuario.employee;
      case 'admin':
        return RolUsuario.admin;
      case 'super_admin':
        return RolUsuario.superAdmin;
      case 'sysadmin':
        return RolUsuario.sysadmin;
      case 'platform_admin':
        return RolUsuario.platformAdmin;
      default:
        return RolUsuario.client;
    }
  }

  String toDbString() {
    switch (this) {
      case RolUsuario.employee:
        return 'employee';
      case RolUsuario.admin:
        return 'admin';
      case RolUsuario.superAdmin:
        return 'super_admin';
      case RolUsuario.sysadmin:
        return 'sysadmin';
      case RolUsuario.platformAdmin:
        return 'platform_admin';
      default:
        return 'client';
    }
  }

  bool get isAdmin => this == RolUsuario.admin || this == RolUsuario.superAdmin;
  bool get isSysadmin => this == RolUsuario.sysadmin;
  bool get isPlatformAdmin => this == RolUsuario.platformAdmin;
  bool get isEmployeeOrAbove =>
      this == RolUsuario.employee || this == RolUsuario.admin ||
      this == RolUsuario.superAdmin || this == RolUsuario.sysadmin;
}
