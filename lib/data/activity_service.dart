import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton que registra sesiones y actividad del usuario en Supabase.
class ServicioActividad {
  static final ServicioActividad instancia = ServicioActividad._();
  ServicioActividad._();

  final _client = Supabase.instance.client;
  String? _sessionId;
  String? _profileId;
  DateTime? _ultimaActualizacion;
  String? _dispositivoCache;
  RealtimeChannel? _canalSesion;
  bool _creandoSesion = false;

  /// Se dispara cuando la sesión fue cerrada remotamente (por sysadmin).
  void Function()? onSesionCerradaRemotamente;

  bool get activo => _sessionId != null || _creandoSesion;

  /// Obtiene el modelo real del dispositivo (ej. "Samsung Galaxy S24", "iPhone 15 Pro")
  Future<String> _obtenerModeloDispositivo() async {
    if (_dispositivoCache != null) return _dispositivoCache!;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        final brand = info.brand;
        final model = info.model;
        debugPrint('[Actividad] Android: $brand $model');
        _dispositivoCache = '$brand $model';
        return _dispositivoCache!;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        debugPrint('[Actividad] iOS: ${info.name} (${info.model})');
        _dispositivoCache = '${info.name} (${info.model})';
        return _dispositivoCache!;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        _dispositivoCache = info.computerName;
        return _dispositivoCache!;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        _dispositivoCache = '${info.model} (${info.computerName})';
        return _dispositivoCache!;
      }
    } catch (e) {
      debugPrint('[Actividad] Error obteniendo info del dispositivo: $e');
    }
    _dispositivoCache = Platform.operatingSystemVersion;
    return _dispositivoCache!;
  }

  /// Verifica si el usuario tiene alguna sesión activa en este dispositivo.
  /// Retorna false si fue cerrada remotamente (por sysadmin).
  Future<bool> tieneSesionActiva(String profileId) async {
    try {
      final dispositivo = await _obtenerModeloDispositivo();
      final existente = await _client
          .from('session_logs')
          .select('id')
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .eq('device', dispositivo)
          .limit(1)
          .maybeSingle();
      return existente != null;
    } catch (e) {
      debugPrint('[Actividad] Error verificando sesión activa: $e');
      return true; // En caso de error, no cerrar sesión
    }
  }

  // ── Iniciar sesión ────────────────────────────────────────
  Future<void> iniciarSesion(String profileId) async {
    if (_creandoSesion) return;
    _creandoSesion = true;
    try {
      _profileId = profileId;
      final dispositivo = await _obtenerModeloDispositivo();
      final plataforma = Platform.operatingSystem;

      // Buscar si ya existe una sesión activa en el mismo dispositivo
      final existente = await _client
          .from('session_logs')
          .select('id')
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .eq('device', dispositivo)
          .order('login_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existente != null) {
        // Reusar la sesión existente en vez de crear una nueva
        _sessionId = existente['id'] as String?;
        _ultimaActualizacion = DateTime.now();
        debugPrint('[Actividad] Sesión existente reusada: $_sessionId');
        _escucharCierrRemoto();
        return;
      }

      // Cerrar sesiones activas anteriores de este usuario en otros dispositivos
      await _client.from('session_logs').update({
        'is_active': false,
        'logout_at': DateTime.now().toIso8601String(),
      }).eq('profile_id', profileId).eq('is_active', true);

      // Crear nueva sesión
      await _client.from('session_logs').insert({
        'profile_id': profileId,
        'platform': plataforma,
        'device': dispositivo,
        'is_active': true,
      });

      // Leer el ID de la sesión recién creada
      final res = await _client
          .from('session_logs')
          .select('id')
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .order('login_at', ascending: false)
          .limit(1)
          .maybeSingle();

      _sessionId = res?['id'] as String?;
      _ultimaActualizacion = DateTime.now();
      debugPrint('[Actividad] Nueva sesión creada: $_sessionId en $dispositivo');
      _escucharCierrRemoto();
    } catch (e) {
      debugPrint('[Actividad] Error al iniciar sesión: $e');
    } finally {
      _creandoSesion = false;
    }
  }

  void _escucharCierrRemoto() {
    _canalSesion?.unsubscribe();
    if (_sessionId == null) return;
    final sid = _sessionId!;
    _canalSesion = _client
        .channel('session_$sid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'session_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sid,
          ),
          callback: (payload) {
            final nuevo = payload.newRecord;
            if (nuevo['is_active'] == false && _sessionId != null) {
              debugPrint('[Actividad] Sesión cerrada remotamente');
              _sessionId = null;
              _profileId = null;
              _ultimaActualizacion = null;
              onSesionCerradaRemotamente?.call();
            }
          },
        )
        .subscribe();
  }

  // ── Registrar vista de pantalla ───────────────────────────
  Future<void> registrarPantalla(String pantalla) async {
    if (_profileId == null) return;
    try {
      await _actualizarUltimaActividad();
      await _client.from('activity_logs').insert({
        'profile_id': _profileId,
        'session_id': _sessionId,
        'event_type': 'screen_view',
        'event_name': pantalla,
      });
    } catch (_) {}
  }

  // ── Registrar tap / acción ────────────────────────────────
  Future<void> registrarTap(String elemento, {Map<String, dynamic>? extra}) async {
    if (_profileId == null) return;
    try {
      await _actualizarUltimaActividad();
      await _client.from('activity_logs').insert({
        'profile_id': _profileId,
        'session_id': _sessionId,
        'event_type': 'tap',
        'event_name': elemento,
        if (extra != null) 'extra': extra,
      });
    } catch (_) {}
  }

  // ── Registrar uso de feature ──────────────────────────────
  Future<void> registrarFeature(String feature) async {
    if (_profileId == null) return;
    try {
      await _actualizarUltimaActividad();
      await _client.from('activity_logs').insert({
        'profile_id': _profileId,
        'session_id': _sessionId,
        'event_type': 'feature',
        'event_name': feature,
      });
    } catch (_) {}
  }

  // ── Cerrar sesión ─────────────────────────────────────────
  Future<void> cerrarSesion() async {
    _canalSesion?.unsubscribe();
    _canalSesion = null;
    if (_sessionId == null) return;
    try {
      await _client.from('session_logs').update({
        'is_active': false,
        'logout_at': DateTime.now().toIso8601String(),
      }).eq('id', _sessionId!);
    } catch (_) {}
    _sessionId = null;
    _profileId = null;
    _ultimaActualizacion = null;
  }

  // ── Actualizar last_active (máx cada 30 seg) ──────────────
  Future<void> _actualizarUltimaActividad() async {
    if (_sessionId == null) return;
    final ahora = DateTime.now();
    if (_ultimaActualizacion != null &&
        ahora.difference(_ultimaActualizacion!).inSeconds < 30) return;
    _ultimaActualizacion = ahora;
    await _client.from('session_logs').update({
      'last_active_at': ahora.toIso8601String(),
    }).eq('id', _sessionId!);
  }
}
