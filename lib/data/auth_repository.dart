import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/profile.dart';

class RepositorioAuth {
  final _client = Supabase.instance.client;

  Future<Perfil> iniciarSesion({required String correo, required String contrasena}) async {
    final resultado = await _client.auth.signInWithPassword(email: correo, password: contrasena);
    if (resultado.user == null) throw Exception('Credenciales incorrectas');

    final perfil = await _obtenerPerfilConReintento(resultado.user!.id);
    if (!perfil.emailVerificado) {
      await _client.auth.signOut();
      throw Exception('email_not_verified');
    }
    return perfil;
  }

  Future<Perfil> registrarse({
    required String correo,
    required String contrasena,
    required String nombreCompleto,
    String? telefono,
  }) async {
    final resultado = await _client.auth.signUp(
      email: correo,
      password: contrasena,
      data: {'full_name': nombreCompleto, 'role': 'client'},
    );
    if (resultado.user == null) throw Exception('Error al crear la cuenta');

    // Esperar a que el trigger cree el perfil
    await Future.delayed(const Duration(seconds: 1));

    // Si el trigger falló, crear el perfil manualmente usando upsert
    final existente = await _client
        .from('profiles')
        .select()
        .eq('id', resultado.user!.id)
        .maybeSingle();

    if (existente == null) {
      await _client.from('profiles').upsert({
        'id': resultado.user!.id,
        'full_name': nombreCompleto,
        'role': 'client',
        'is_active': true,
      });
    }

    if (telefono != null && telefono.isNotEmpty) {
      await _client.from('profiles').update({'phone': telefono}).eq('id', resultado.user!.id);
    }

    // El registro nunca deja al usuario logueado: debe confirmar su correo
    // (enviado con nuestro propio SMTP) antes de poder iniciar sesión.
    if (resultado.session != null) {
      try {
        await _enviarCorreoConfirmacion();
      } catch (_) {}
      await _client.auth.signOut();
    }
    throw Exception('email_confirmation_required');
  }

  Future<void> _enviarCorreoConfirmacion() async {
    final session = _client.auth.currentSession;
    if (session == null) return;
    await http.post(
      Uri.parse('$kSupabaseUrl/functions/v1/send-confirmation-email'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );
  }

  /// Envía el correo de recuperación (vía nuestro SMTP) si el correo existe.
  /// Siempre "tiene éxito" desde el punto de vista de la UI, para no revelar
  /// si una cuenta existe o no.
  Future<void> solicitarRecuperacionContrasena(String correo) async {
    await http.post(
      Uri.parse('$kSupabaseUrl/functions/v1/send-password-reset-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': correo}),
    );
  }

  Future<Perfil?> obtenerPerfilActual() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    return _obtenerPerfilConReintento(usuario.id);
  }

  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  // Reintenta hasta 3 veces con delay (por si el trigger tarda)
  Future<Perfil> _obtenerPerfilConReintento(String idUsuario, {int reintentos = 3}) async {
    for (int i = 0; i < reintentos; i++) {
      final datos = await _client
          .from('profiles')
          .select()
          .eq('id', idUsuario)
          .maybeSingle();

      if (datos != null) return Perfil.fromMap(datos);

      if (i < reintentos - 1) await Future.delayed(const Duration(milliseconds: 800));
    }
    throw Exception('No se encontró el perfil. Intenta iniciar sesión.');
  }

  Future<void> actualizarPerfil(String idUsuario, Map<String, dynamic> actualizaciones) async {
    await _client.from('profiles').update(actualizaciones).eq('id', idUsuario);
  }

  Future<String> subirAvatar(String idUsuario, Uint8List bytes, String formato) async {
    final ruta = '$idUsuario/avatar.$formato';
    await _client.storage.from('avatars').uploadBinary(
      ruta,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: 'image/$formato'),
    );
    return _client.storage.from('avatars').getPublicUrl(ruta);
  }

  Stream<AuthState> get cambiosEstadoAuth => _client.auth.onAuthStateChange;
}
