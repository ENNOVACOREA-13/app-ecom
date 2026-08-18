import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../data/activity_service.dart';
import '../domain/models/profile.dart';

/// Traduce un error crudo de auth (Supabase/GoTrue) a un mensaje que el
/// usuario entienda, sin exponer detalles internos del servidor.
String parsearErrorAuth(String e) {
  if (e.contains('account_deactivated')) return 'Tu cuenta ha sido desactivada. Contacta al administrador';
  if (e.contains('Invalid login')) return 'Email o contraseña incorrectos';
  if (e.contains('already registered') || e.contains('User already registered')) return 'Este email ya está registrado';
  if (e.contains('Password should')) return 'La contraseña debe tener al menos 6 caracteres';
  if (e.contains('valid email')) return 'Ingresa un email válido';
  if (e.contains('email_confirmation_required')) return 'Revisa tu correo para confirmar tu cuenta antes de entrar';
  if (e.contains('email_not_verified')) return 'Confirma tu correo antes de iniciar sesión. Revisa tu bandeja de entrada (y spam)';
  if (e.contains('row-level security') || e.contains('violates') || e.contains('42501')) return 'Error de permisos en la base de datos. Contacta al administrador';
  if (e.contains('does not exist') || e.contains('relation')) return 'Error de configuración en la base de datos';
  if (e.contains('Email rate limit') || e.contains('rate limit')) return 'Demasiados intentos. Espera unos minutos';
  final eMin = e.toLowerCase();
  if (eMin.contains('network') || eMin.contains('socket')) return 'Sin conexión a internet';
  if (eMin.contains('timeout')) return 'La solicitud tardó demasiado. Intenta de nuevo';
  debugPrint('[AuthError] $e');
  return 'Ocurrió un error inesperado. Intenta de nuevo';
}

class ProveedorAuth extends ChangeNotifier {
  final _repo = RepositorioAuth();
  StreamSubscription<AuthState>? _authSub;

  Perfil? _perfil;
  bool _cargando = false;
  bool _inicializando = true;
  String? _error;
  bool _sesionExpirada = false;
  bool _cuentaDesactivada = false;

  bool get sesionExpirada => _sesionExpirada;
  void limpiarSesionExpirada() {
    _sesionExpirada = false;
    notifyListeners();
  }

  bool get cuentaDesactivada => _cuentaDesactivada;
  void limpiarCuentaDesactivada() {
    _cuentaDesactivada = false;
    notifyListeners();
  }

  Perfil? get perfil => _perfil;
  bool get cargando => _cargando;
  bool get inicializando => _inicializando;
  String? get error => _error;
  bool get estaConectado => _perfil != null;

  Future<void> inicializar() async {
    try {
      _perfil = await _repo.obtenerPerfilActual();
      if (_perfil != null && !_perfil!.estaActivo) {
        debugPrint('[Auth] Cuenta desactivada, forzando logout');
        _cuentaDesactivada = true;
        await _repo.cerrarSesion();
        _perfil = null;
      }
      if (_perfil != null) {
        final rol = _perfil!.rol.name;
        // Para no-sysadmin, verificar si la sesión fue cerrada remotamente
        if (rol != 'sysadmin') {
          final tieneActiva = await ServicioActividad.instancia
              .tieneSesionActiva(_perfil!.id);
          if (!tieneActiva) {
            debugPrint('[Auth] Sesión cerrada remotamente, forzando logout');
            _sesionExpirada = true;
            await _repo.cerrarSesion();
            _perfil = null;
          }
        }
        // Registrar sesión al restaurar (reinicio de app con sesión activa)
        if (_perfil != null && !ServicioActividad.instancia.activo) {
          await ServicioActividad.instancia.iniciarSesion(_perfil!.id);
        }
      }
    } catch (e) {
      debugPrint('[Auth] Error al restaurar sesión: $e');
      _perfil = null;
    } finally {
      _inicializando = false;
      notifyListeners();
    }

    // Escuchar cierre remoto de sesión (sysadmin cerró la sesión)
    ServicioActividad.instancia.onSesionCerradaRemotamente = () async {
      if (_perfil == null) return;
      final rol = _perfil!.rol.name;
      // Solo mostrar modal a clientes, empleados y admins (no sysadmin)
      if (rol == 'sysadmin') return;
      _sesionExpirada = true;
      await _repo.cerrarSesion();
      _perfil = null;
      notifyListeners();
    };

    // Escuchar desactivación de cuenta en tiempo real (admin/sysadmin la desactivó)
    ServicioActividad.instancia.onCuentaDesactivada = () async {
      if (_perfil == null) return;
      _cuentaDesactivada = true;
      await ServicioActividad.instancia.cerrarSesion();
      await _repo.cerrarSesion();
      _perfil = null;
      notifyListeners();
    };

    // Escuchar cambios de sesión (OAuth, logout, nuevos logins)
    _authSub = _repo.cambiosEstadoAuth.listen((estado) async {
      if (estado.event == AuthChangeEvent.signedIn) {
        try {
          _sesionExpirada = false;
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
      _sesionExpirada = false;
      _perfil = await _repo.iniciarSesion(correo: correo, contrasena: contrasena);
      await ServicioActividad.instancia.iniciarSesion(_perfil!.id);
      return true;
    } catch (e) {
      _error = parsearErrorAuth(e.toString());
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
      _sesionExpirada = false;
      _perfil = await _repo.registrarse(
        correo: correo,
        contrasena: contrasena,
        nombreCompleto: nombreCompleto,
        telefono: telefono,
      );
      await ServicioActividad.instancia.iniciarSesion(_perfil!.id);
      return true;
    } catch (e) {
      _error = parsearErrorAuth(e.toString());
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> solicitarRecuperacionContrasena(String correo) async {
    try {
      await _repo.solicitarRecuperacionContrasena(correo);
    } catch (_) {}
  }

  void iniciarSesionConGoogle() {
    _error = null;
    notifyListeners();
    Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.barbershop://login-callback',
    );
  }

  void iniciarSesionConFacebook() {
    _error = null;
    notifyListeners();
    Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : 'io.supabase.barbershop://login-callback',
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

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
