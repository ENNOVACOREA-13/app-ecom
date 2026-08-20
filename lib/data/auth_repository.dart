import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/profile.dart';

class RepositorioAuth {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Perfil> iniciarSesion({required String correo, required String contrasena}) async {
    final resultado = await _client.auth.signInWithPassword(email: correo, password: contrasena);
    if (resultado.user == null) throw Exception('Credenciales incorrectas');

    final Perfil perfil;
    try {
      perfil = await _obtenerPerfilConReintento(resultado.user!.id);
    } catch (e) {
      // Credenciales válidas en Supabase Auth pero sin fila en profiles
      // (ej. un platform_admin eliminó la cuenta desde el panel) — sin este
      // signOut() la sesión queda "colgada": autenticada pero sin perfil.
      await _client.auth.signOut();
      throw Exception('profile_not_found');
    }
    // Cuenta real, contraseña real, pero de OTRO negocio: se rechaza con el
    // mismo mensaje/estado que unas credenciales inválidas — nunca debe
    // distinguirse de un login fallido, o se estaría confirmando que ese
    // correo/contraseña sí existen en algún otro negocio.
    if (!perfil.perteneceATenant(kTenantIdActivo)) {
      await _client.auth.signOut();
      throw Exception('Invalid login credentials');
    }
    if (!perfil.estaActivo) {
      await _client.auth.signOut();
      throw Exception('account_deactivated');
    }
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
      data: {'full_name': nombreCompleto, 'role': 'client', 'tenant_id': kTenantIdActivo},
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
        'tenant_id': kTenantIdActivo,
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
  /// si una cuenta existe o no. Manda el tenant del dominio actual para que
  /// el enlace de "ir a iniciar sesión" en la página de éxito apunte al
  /// negocio desde el que se pidió — sin esto, una cuenta con acceso a
  /// varios negocios (ej. admin invitado a un segundo negocio) siempre
  /// recibía el enlace de su negocio "de casa" fijo, sin importar desde
  /// cuál pidió el cambio.
  Future<void> solicitarRecuperacionContrasena(String correo) async {
    await http.post(
      Uri.parse('$kSupabaseUrl/functions/v1/send-password-reset-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': correo,
        if (kTenantIdActivo != null) 'tenant_id': kTenantIdActivo,
      }),
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

  // Reintenta hasta 3 veces con delay (por si el trigger tarda). Usa
  // obtener_mi_perfil_efectivo() en vez de leer profiles directo: si esta
  // cuenta tiene una membresía admin-nivel extra para el negocio del
  // dominio actual (ver 20260819130000), el rol/tenant que regresa reflejan
  // ESE negocio, no el rol fijo de su cuenta "de casa".
  Future<Perfil> _obtenerPerfilConReintento(String idUsuario, {int reintentos = 3}) async {
    for (int i = 0; i < reintentos; i++) {
      final filas = await _client.rpc('obtener_mi_perfil_efectivo') as List;
      if (filas.isNotEmpty) return Perfil.fromMap(filas.first as Map<String, dynamic>);

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
    // La ruta siempre es la misma (upsert sobre el mismo archivo), así que
    // se agrega un parámetro con la hora para invalidar la caché de imagen
    // (CachedNetworkImageProvider cachea por URL): sin esto, el avatar
    // nuevo no se ve hasta refrescar el navegador aunque el archivo ya
    // haya cambiado en el storage.
    final url = _client.storage.from('avatars').getPublicUrl(ruta);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Stream<AuthState> get cambiosEstadoAuth => _client.auth.onAuthStateChange;
}
