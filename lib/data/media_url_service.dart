import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// El bucket `media` es privado (migración 20260819160000) — la única
/// forma de conseguir una URL que sirva la imagen es que media-sign-url
/// (Edge Function) confirme que la cuenta actual es admin/sysadmin del
/// tenant dueño de ese path, y la firme. Sin esto nadie puede armar una
/// URL válida para el bucket, ni adivinar/listar imágenes de OTRO negocio.
class ServicioUrlMedia {
  static Future<String> firmarUrlMedia(String ruta) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Sin sesión activa.');

    final respuesta = await http.post(
      Uri.parse('$kSupabaseUrl/functions/v1/media-sign-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'path': ruta}),
    );

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
    if (respuesta.statusCode != 200 || datos['success'] != true) {
      throw Exception('No se pudo generar la URL de la imagen.');
    }

    final separador = (datos['url'] as String).contains('?') ? '&' : '?';
    return '${datos['url']}${separador}v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
