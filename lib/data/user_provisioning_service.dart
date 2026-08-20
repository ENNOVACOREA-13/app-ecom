import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// Traduce los códigos de error de admin-create-user a un mensaje legible.
String mapearErrorInvitacion(String e) {
  final codigo = e.replaceFirst('Exception: ', '').trim();
  switch (codigo) {
    case 'email_already_exists':
      return 'Ese correo ya tiene una cuenta.';
    case 'invalid_email':
      return 'El correo no es válido.';
    case 'invalid_name':
      return 'Ingresa un nombre.';
    case 'role_not_allowed':
      return 'No tienes permiso para asignar ese rol.';
    case 'invalid_tenant':
    case 'missing_tenant_id':
      return 'No se pudo determinar el negocio.';
    case 'missing_auth':
    case 'invalid_session':
    case 'forbidden':
      return 'Tu sesión no tiene permiso para hacer esto.';
    default:
      return 'No se pudo enviar la invitación.';
  }
}

/// Traduce los códigos de error de admin-delete-user a un mensaje legible.
String mapearErrorEliminacion(String e) {
  final codigo = e.replaceFirst('Exception: ', '').trim();
  switch (codigo) {
    case 'cannot_delete_sysadmin':
      return 'Las cuentas sysadmin no se pueden eliminar.';
    case 'cannot_delete_self':
      return 'No puedes eliminar tu propia cuenta desde aquí.';
    case 'role_not_allowed':
    case 'forbidden':
      return 'No tienes permiso para eliminar esta cuenta.';
    case 'user_not_found':
      return 'Esa cuenta ya no existe.';
    case 'missing_auth':
    case 'invalid_session':
      return 'Tu sesión no tiene permiso para hacer esto.';
    default:
      return 'No se pudo eliminar la cuenta.';
  }
}

/// Crea cuentas con rol elevado (empleado/admin/sysadmin) a través de la
/// Edge Function `admin-create-user`: el permiso se valida server-side
/// contra el rol real de quien llama, nunca confiando en lo que mande el
/// cliente. Se le manda una invitación por correo para que la persona
/// configure su propia contraseña (ver 20260819100000_fix_role_escalation_holes.sql).
class ServicioAltaUsuarios {
  /// Devuelve el id del usuario recién creado.
  Future<String> invitarUsuario({
    required String email,
    required String fullName,
    required String role,
    String? tenantId,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('missing_session');

    final respuesta = await http.post(
      Uri.parse('$kSupabaseUrl/functions/v1/admin-create-user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'role': role,
        if (tenantId != null) 'tenant_id': tenantId,
      }),
    );

    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    if (cuerpo['success'] != true) {
      throw Exception(cuerpo['error'] ?? 'unknown_error');
    }
    return cuerpo['id'] as String;
  }

  /// Elimina una cuenta por completo (perfil + cuenta de Supabase Auth) a
  /// través de la Edge Function `admin-delete-user` — así el correo queda
  /// libre para un registro nuevo, en vez de dejar una cuenta de Auth
  /// "colgada" sin perfil (ver RepositorioAuth.iniciarSesion). El permiso
  /// se valida server-side igual que en invitarUsuario().
  Future<void> eliminarUsuario(String userId) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('missing_session');

    final respuesta = await http.post(
      Uri.parse('$kSupabaseUrl/functions/v1/admin-delete-user'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({'user_id': userId}),
    );

    final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
    if (cuerpo['success'] != true) {
      throw Exception(cuerpo['error'] ?? 'unknown_error');
    }
  }
}
