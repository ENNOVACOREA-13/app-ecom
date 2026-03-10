class ConfigApp {
  final String idApp;
  final String slug;
  final String nombre;
  final String colorPrimario;
  final String colorFondo;
  final String? logoBase64;

  ConfigApp({
    required this.idApp,
    required this.slug,
    required this.nombre,
    required this.colorPrimario,
    required this.colorFondo,
    this.logoBase64,
  });

  factory ConfigApp.fromMaps(Map<String, dynamic> app, Map<String, dynamic>? cfg) {
    return ConfigApp(
      idApp: app['id'],
      slug: app['slug'],
      nombre: app['name'],
      colorPrimario: (cfg?['primary_color'] ?? '#7C3AED') as String,
      colorFondo: (cfg?['background_color'] ?? '#000000') as String,
      logoBase64: cfg?['logo_base64'] as String?,
    );
  }
}
