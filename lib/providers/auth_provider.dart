import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/activity_service.dart';
import '../domain/models/profile.dart';

class ProveedorAuth extends ChangeNotifier {
  final _repo = RepositorioAuth();
  StreamSubscription<AuthState>? _authSub;

  Perfil? _perfil;
  bool _cargando = false;
  bool _inicializando = true;
  String? _error;

  Perfil? get perfil => _perfil;
  bool get cargando => _cargando;
  bool get inicializando => _inicializando;
  String? get error => _error;
  bool get estaConectado => _perfil != null;

  Future<void> inicializar() async {
    try {
      _perfil = await _repo.obtenerPerfilActual();
      // Registrar sesión al restaurar (reinicio de app con sesión activa)
      if (_perfil != null && !ServicioActividad.instancia.activo) {
        await ServicioActividad.instancia.iniciarSesion(_perfil!.id);
      }
    } catch (e) {
      debugPrint('[Auth] Error al restaurar sesión: $e');
      _perfil = null;
    } finally {
      _inicializando = false;
      notifyListeners();
    }

    // Escuchar cambios de sesión (OAuth, logout, nuevos logins)
    _authSub = _repo.cambiosEstadoAuth.listen((estado) async {
      if (estado.event == AuthChangeEvent.signedIn) {
        try {
          _perfil = await _repo.obtenerPerfilActual();
          if (_perfil != null && !ServicioActividad.instancia.activo) {
            await ServicioActividad.instancia.iniciarSesion(_perfil!.id);
          }
        } catch (e) {
          debugPrint('[Auth] Error al cargar perfil tras signedIn: $e');
        }
        _cargando = false;
        notifyListeners();
      } else if (estado.event == AuthChangeEvent.signedOut) {
        _perfil = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<bool> iniciarSesion(String correo, String contrasena) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await _repo.iniciarSesion(correo: correo, contrasena: contrasena);
      await ServicioActividad.instancia.iniciarSesion(_perfil!.id);
      return true;
    } catch (e) {
      _error = _parsearError(e.toString());
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> registrarse({
    required String correo,
    required String contrasena,
    required String nombreCompleto,
    String? telefono,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await _repo.registrarse(
        correo: correo,
        contrasena: contrasena,
        nombreCompleto: nombreCompleto,
        telefono: telefono,
      );
      await ServicioActividad.instancia.iniciarSesion(_perfil!.id);
      return true;
    } catch (e) {
      _error = _parsearError(e.toString());
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void iniciarSesionConGoogle() {
    _error = null;
    notifyListeners();
    Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.barbershop://login-callback',
    );
  }

  void iniciarSesionConFacebook() {
    _error = null;
    notifyListeners();
    Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.barbershop://login-callback',
    );
  }

  Future<void> cerrarSesion() async {
    await ServicioActividad.instancia.cerrarSesion();
    await _repo.cerrarSesion();
    _perfil = null;
    notifyListeners();
  }

  Future<void> actualizarPerfil(Map<String, dynamic> actualizaciones) async {
    if (_perfil == null) return;
    await _repo.actualizarPerfil(_perfil!.id, actualizaciones);
    _perfil = await _repo.obtenerPerfilActual();
    notifyListeners();
  }

  Future<void> subirAvatar(Uint8List bytes, String formato) async {
    if (_perfil == null) return;
    final url = await _repo.subirAvatar(_perfil!.id, bytes, formato);
    await actualizarPerfil({'avatar_url': url});
  }

  String _parsearError(String e) {
    if (e.contains('Invalid login')) return 'Email o contraseña incorrectos';
    if (e.contains('already registered') || e.contains('User already registered')) return 'Este email ya está registrado';
    if (e.contains('Password should')) return 'La contraseña debe tener al menos 6 caracteres';
    if (e.contains('valid email')) return 'Ingresa un email válido';
    if (e.contains('network') || e.contains('socket')) return 'Sin conexión a internet';
    if (e.contains('timeout')) return 'La solicitud tardó demasiado. Intenta de nuevo';
    if (e.contains('email_confirmation_required')) return 'Revisa tu correo para confirmar tu cuenta antes de entrar';
    if (e.contains('row-level security') || e.contains('violates') || e.contains('42501')) return 'Error de permisos en la base de datos. Contacta al administrador';
    if (e.contains('does not exist') || e.contains('relation')) return 'Error de configuración en la base de datos';
    if (e.contains('Email rate limit') || e.contains('rate limit')) return 'Demasiados intentos. Espera unos minutos';
    debugPrint('[AuthError] $e');
    return 'Ocurrió un error inesperado. Intenta de nuevo';
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
