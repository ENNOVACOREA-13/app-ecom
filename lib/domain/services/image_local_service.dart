import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ServicioImagenLocal {
  static const _k = 'perfil_imagen_base64';

  Future<void> guardarBase64(String base64) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, base64);
  }

  Future<String?> leerBase64() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_k);
  }

  Future<void> borrar() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_k);
  }
}
