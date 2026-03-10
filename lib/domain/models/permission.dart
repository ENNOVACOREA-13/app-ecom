class PermisoApp {
  final String clave; // VER_TIENDA, VER_RESERVAS...
  final bool habilitado;
  PermisoApp({required this.clave, required this.habilitado});
  factory PermisoApp.fromMap(Map<String, dynamic> m) =>
      PermisoApp(clave: m['key'], habilitado: m['enabled'] == true);
}
