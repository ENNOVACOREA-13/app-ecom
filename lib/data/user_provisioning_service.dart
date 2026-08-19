import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

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
}
