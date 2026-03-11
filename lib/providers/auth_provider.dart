import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../domain/models/profile.dart';

class ProveedorAuth extends ChangeNotifier {
  final _repo = RepositorioAuth();

  Perfil? _perfil;
  bool _cargando = false;
  String? _error;

  Perfil? get perfil => _perfil;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get estaConectado => _perfil != null;

  Future<void> inicializar() async {
    _perfil = await _repo.obtenerPerfilActual();
    notifyListeners();
  }

  Future<bool> iniciarSesion(String correo, String contrasena) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await _repo.iniciarSesion(correo: correo, contrasena: contrasena);
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
      return true;
    } catch (e) {
      _error = _parsearError(e.toString());
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
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
    if (e.contains('already registered')) return 'Este email ya está registrado';
    if (e.contains('Password should')) return 'La contraseña debe tener al menos 6 caracteres';
    if (e.contains('valid email')) return 'Ingresa un email válido';
    if (e.contains('network') || e.contains('socket')) return 'Sin conexión a internet';
    if (e.contains('timeout')) return 'La solicitud tardó demasiado. Intenta de nuevo';
    return 'Ocurrió un error inesperado. Intenta de nuevo';
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
