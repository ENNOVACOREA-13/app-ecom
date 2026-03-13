import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/profile.dart';

class RepositorioAuth {
  final _client = Supabase.instance.client;

  Future<Perfil> iniciarSesion({required String correo, required String contrasena}) async {
    final resultado = await _client.auth.signInWithPassword(email: correo, password: contrasena);
    if (resultado.user == null) throw Exception('Credenciales incorrectas');
    return _obtenerPerfilConReintento(resultado.user!.id);
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

    // Si Supabase requiere confirmación de email, no hay sesión activa
    if (resultado.session == null) {
      throw Exception('email_confirmation_required');
    }

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

    return _obtenerPerfilConReintento(resultado.user!.id);
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
