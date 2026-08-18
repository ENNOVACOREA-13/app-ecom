import 'package:flutter/material.dart';
import '../data/service_repository.dart';
import '../domain/models/service_model.dart';

/// Aplica un mapa parcial de [cambios] sobre [original] para actualizar la
/// lista local de forma optimista, sin esperar a recargar del servidor.
/// Los campos ausentes en [cambios] conservan su valor original.
ModeloServicio aplicarActualizacionServicio(
    ModeloServicio original, Map<String, dynamic> cambios) {
  return ModeloServicio.fromMap({
    'id': original.id,
    'name': cambios['name'] ?? original.nombre,
    'description': cambios['description'] ?? original.descripcion,
    'duration_min': cambios['duration_min'] ?? original.duracionMin,
    'price': cambios['price'] ?? original.precio,
    'image_url': cambios['image_url'] ?? original.urlImagen,
    'is_active': cambios['is_active'] ?? original.estaActivo,
    'icon_name': cambios.containsKey('icon_name')
        ? cambios['icon_name']
        : original.iconoNombre,
    'icon_color': cambios.containsKey('icon_color')
        ? cambios['icon_color']
        : original.iconoColor,
  });
}

class ProveedorServicio extends ChangeNotifier {
  ProveedorServicio({RepositorioServicio? repo}) : _repo = repo ?? RepositorioServicio();

  final RepositorioServicio _repo;

  List<ModeloServicio> _servicios = [];
  bool _cargando = false;
  String? _error;

  List<ModeloServicio> get servicios => _servicios;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarServicios({bool esVistaAdmin = false}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _servicios = esVistaAdmin ? await _repo.obtenerTodosLosServicios() : await _repo.obtenerServiciosActivos();
    } catch (e) {
      _error = 'Error al cargar servicios: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crearServicio(ModeloServicio servicio) async {
    try {
      final creado = await _repo.crearServicio(servicio);
      _servicios.insert(0, creado);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al crear servicio: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> actualizarServicio(String id, Map<String, dynamic> actualizaciones) async {
    await _repo.actualizarServicio(id, actualizaciones);
    _servicios = _servicios
        .map((s) => s.id == id ? aplicarActualizacionServicio(s, actualizaciones) : s)
        .toList();
    notifyListeners();
  }

  Future<void> eliminarServicio(String id) async {
    await _repo.eliminarServicio(id);
    _servicios = _servicios.where((s) => s.id != id).toList();
    notifyListeners();
  }
}
