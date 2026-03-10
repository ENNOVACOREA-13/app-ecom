enum RolUsuario {
  client,
  employee,
  admin,
  superAdmin;

  static RolUsuario fromString(String value) {
    switch (value) {
      case 'employee':
        return RolUsuario.employee;
      case 'admin':
        return RolUsuario.admin;
      case 'super_admin':
        return RolUsuario.superAdmin;
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
      default:
        return 'client';
    }
  }

  bool get isAdmin => this == RolUsuario.admin || this == RolUsuario.superAdmin;
  bool get isEmployeeOrAbove =>
      this == RolUsuario.employee || this == RolUsuario.admin || this == RolUsuario.superAdmin;
}
