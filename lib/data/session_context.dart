import 'package:supabase_flutter/supabase_flutter.dart';

class SessionContext {
  final String userId;
  final String role; // admin_supremo | admin | empleado | usuario
  final List<String> appIds;
  final Map<String, bool> permissions; // key -> enabled

  bool get isAdmin => role == 'admin' || role == 'admin_supremo';
  bool get isEmpleado => role == 'empleado';
  bool get canEditProducts => isAdmin || isEmpleado;

  const SessionContext({
    required this.userId,
    required this.role,
    required this.appIds,
    required this.permissions,
  });

  static Future<SessionContext> load() async {
    final sb = Supabase.instance.client;
    final resp = await sb.from('v_current_context').select().single();
    final perms = <String, bool>{};
    if (resp['permissions'] != null) {
      for (final p in (resp['permissions'] as List)) {
        perms[p['key'] as String] = p['enabled'] as bool;
      }
    }
    return SessionContext(
      userId: resp['user_id'] as String,
      role: resp['role'] as String,
      appIds: (resp['app_ids'] as List?)?.map((e) => e as String).toList() ??
          const [],
      permissions: perms,
    );
  }
}
