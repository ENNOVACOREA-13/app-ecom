class RoleService {
  static const String usuario = 'usuario';
  static const String empleado = 'empleado';
  static const String admin = 'admin';
  static const String adminSupremo = 'admin_supremo';

  // Permisos para cada rol
  static bool puedeCrearProductos(String rol) {
    return rol == empleado || rol == admin || rol == adminSupremo;
  }

  static bool puedeCrearReservas(String rol) {
    return true; // Todos pueden crear reservas
  }

  static bool puedeVerTodasLasReservas(String rol) {
    return rol == admin || rol == adminSupremo;
  }

  static bool puedeVerReservasEmpleado(String rol) {
    return rol == empleado || rol == admin || rol == adminSupremo;
  }

  static bool puedeVerSoloSusReservas(String rol) {
    return rol == usuario;
  }

  static bool esEmpleado(String rol) {
    return rol == empleado;
  }

  static bool esAdmin(String rol) {
    return rol == admin || rol == adminSupremo;
  }

  static bool puedeEditarProductos(String rol) {
    return rol == empleado || rol == admin || rol == adminSupremo;
  }

  static bool puedeEliminarProductos(String rol) {
    return rol == empleado || rol == admin || rol == adminSupremo;
  }

  static bool puedeGestionarProductos(String rol) {
    return rol == empleado || rol == admin || rol == adminSupremo;
  }
}
