import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/app_notification.dart';

class RepositorioNotificaciones {
  final _client = Supabase.instance.client;
  RealtimeChannel? _canal;

  Future<List<NotificacionApp>> obtenerNotificaciones(String userId) async {
    final datos = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (datos as List)
        .map((e) => NotificacionApp.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarLeida(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<void> marcarTodasLeidas(String userId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  void suscribirse(String userId, void Function(NotificacionApp) onNueva) {
    _canal?.unsubscribe();
    _canal = _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onNueva(NotificacionApp.fromMap(payload.newRecord));
          },
        )
        .subscribe();
  }

  void cancelarSuscripcion() {
    _canal?.unsubscribe();
    _canal = null;
  }
}
