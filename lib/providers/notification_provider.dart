import 'package:flutter/material.dart';
import '../data/notification_repository.dart';
import '../domain/models/app_notification.dart';

class ProveedorNotificaciones extends ChangeNotifier {
  ProveedorNotificaciones({RepositorioNotificaciones? repo}) : _repo = repo ?? RepositorioNotificaciones();

  final RepositorioNotificaciones _repo;
  String? _userId;
  List<NotificacionApp> _notificaciones = [];
  bool _cargando = false;

  List<NotificacionApp> get notificaciones => List.unmodifiable(_notificaciones);
  int get noLeidas => _notificaciones.where((n) => !n.leida).length;
  bool get cargando => _cargando;

  Future<void> iniciar(String userId) async {
    if (_userId == userId) return;
    _userId = userId;
    await cargar();
    _repo.suscribirse(userId, (nueva) {
      _notificaciones.insert(0, nueva);
      notifyListeners();
    });
  }

  Future<void> cargar() async {
    final userId = _userId;
    if (userId == null) return;
    _cargando = true;
    notifyListeners();
    try {
      _notificaciones = await _repo.obtenerNotificaciones(userId);
    } catch (_) {}
    _cargando = false;
    notifyListeners();
  }

  Future<void> marcarLeida(String id) async {
    final idx = _notificaciones.indexWhere((n) => n.id == id);
    if (idx == -1 || _notificaciones[idx].leida) return;
    final anterior = _notificaciones[idx];
    _notificaciones[idx] = NotificacionApp(
      id: anterior.id,
      titulo: anterior.titulo,
      cuerpo: anterior.cuerpo,
      tipo: anterior.tipo,
      relatedId: anterior.relatedId,
      leida: true,
      creadaEn: anterior.creadaEn,
    );
    notifyListeners();
    try {
      await _repo.marcarLeida(id);
    } catch (_) {}
  }

  Future<void> marcarTodasLeidas() async {
    final userId = _userId;
    if (userId == null) return;
    _notificaciones = _notificaciones
        .map((n) => NotificacionApp(
              id: n.id,
              titulo: n.titulo,
              cuerpo: n.cuerpo,
              tipo: n.tipo,
              relatedId: n.relatedId,
              leida: true,
              creadaEn: n.creadaEn,
            ))
        .toList();
    notifyListeners();
    try {
      await _repo.marcarTodasLeidas(userId);
    } catch (_) {}
  }

  void detener() {
    _repo.cancelarSuscripcion();
    _userId = null;
    _notificaciones = [];
    notifyListeners();
  }
}
