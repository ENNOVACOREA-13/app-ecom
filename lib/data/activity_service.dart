import 'dart:io';
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

  bool get activo => _sessionId != null;

  // ── Iniciar sesión ────────────────────────────────────────
  Future<void> iniciarSesion(String profileId) async {
    try {
      _profileId = profileId;
      final plataforma = Platform.operatingSystem;
      final dispositivo = Platform.operatingSystemVersion;

      // Insertar sin .select() para evitar problemas de RLS en SELECT
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
    } catch (e) {
      debugPrint('[Actividad] Error al iniciar sesión: $e');
    }
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
