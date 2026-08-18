import 'package:flutter/material.dart';
import '../data/saved_repository.dart';

class ProveedorGuardados extends ChangeNotifier {
  ProveedorGuardados({RepositorioGuardados? repo}) : _repo = repo ?? RepositorioGuardados();

  final RepositorioGuardados _repo;

  String? _userId;
  final Set<String> _guardados = {};
  bool _cargando = false;

  Set<String> get guardados => Set.unmodifiable(_guardados);
  bool get cargando => _cargando;
  bool estaGuardado(String productId) => _guardados.contains(productId);

  Future<void> cargar(String userId) async {
    _userId = userId;
    _cargando = true;
    notifyListeners();
    try {
      final ids = await _repo.obtenerGuardados(userId);
      _guardados
        ..clear()
        ..addAll(ids);
    } catch (_) {}
    _cargando = false;
    notifyListeners();
  }

  Future<void> toggleGuardado(String productId) async {
    if (_userId == null) return;
    final estabaGuardado = _guardados.contains(productId);
    // Actualización optimista
    if (estabaGuardado) {
      _guardados.remove(productId);
    } else {
      _guardados.add(productId);
    }
    notifyListeners();
    try {
      if (estabaGuardado) {
        await _repo.quitar(_userId!, productId);
      } else {
        await _repo.guardar(_userId!, productId);
      }
    } catch (_) {
      // Revertir si falla
      if (estabaGuardado) {
        _guardados.add(productId);
      } else {
        _guardados.remove(productId);
      }
      notifyListeners();
    }
  }

  void limpiar() {
    _userId = null;
    _guardados.clear();
    notifyListeners();
  }
}
