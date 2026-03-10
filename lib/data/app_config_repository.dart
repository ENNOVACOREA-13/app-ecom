import 'package:flutter/material.dart';
import '../domain/models/app_config.dart';
import '../domain/models/permission.dart';
import 'supabase_service.dart';

class RepoConfigApp {
  Future<ConfigApp> obtenerConfig(String slugApp) async {
    final app = await sbSingle('apps', where: {'slug': slugApp});
    if (app == null) throw Exception('App no encontrada');
    final cfg = await sbSingle('app_configs', where: {'app_id': app['id']});
    return ConfigApp.fromMaps(app, cfg);
  }

  Future<List<PermisoApp>> obtenerPermisos(String slugApp) async {
    final app = await sbSingle('apps', where: {'slug': slugApp});
    if (app == null) return [];
    final lista =
        await sbSelect('app_permissions', where: {'app_id': app['id']});
    return lista.map(PermisoApp.fromMap).toList();
  }

  Future<void> actualizarTema(
    String slugApp, {
    String? colorPrimario,
    String? colorFondo,
    String? logoBase64,
  }) async {
    final app = await sbSingle('apps', where: {'slug': slugApp});
    if (app == null) throw Exception('App no encontrada');
    final exist = await sbSingle('app_configs', where: {'app_id': app['id']});
    final payload = <String, dynamic>{
      'app_id': app['id'],
      if (colorPrimario != null) 'primary_color': colorPrimario,
      if (colorFondo != null) 'background_color': colorFondo,
      if (logoBase64 != null) 'logo_base64': logoBase64,
    };
    if (exist == null) {
      await sbInsertReturn('app_configs', payload);
    } else {
      payload['id'] = exist['id'];
      await sbUpdate('app_configs', payload, where: {'id': exist['id']});
    }
  }
}

class ControlTemaLogin with ChangeNotifier {
  String colorPrimarioHex = '#7C3AED';
  String colorFondoHex = '#000000';
  String? logoBase64;

  void aplicar(ConfigApp c) {
    colorPrimarioHex = c.colorPrimario;
    colorFondoHex = c.colorFondo;
    logoBase64 = c.logoBase64;
    notifyListeners();
  }

  Color get colorPrimario => _hex(colorPrimarioHex);
  Color get colorFondo => _hex(colorFondoHex);

  Color _hex(String h) {
    var x = h.replaceAll('#', '');
    if (x.length == 6) x = 'FF$x';
    return Color(int.parse(x, radix: 16));
  }
}
