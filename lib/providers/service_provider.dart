import 'package:flutter/material.dart';
import '../data/service_repository.dart';
import '../domain/models/service_model.dart';

class ProveedorServicio extends ChangeNotifier {
  final _repo = RepositorioServicio();

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
    _servicios = _servicios.map((s) {
      if (s.id != id) return s;
      return ModeloServicio.fromMap({
        'id': s.id,
        'name': actualizaciones['name'] ?? s.nombre,
        'description': actualizaciones['description'] ?? s.descripcion,
        'duration_min': actualizaciones['duration_min'] ?? s.duracionMin,
        'price': actualizaciones['price'] ?? s.precio,
        'image_url': actualizaciones['image_url'] ?? s.urlImagen,
        'is_active': actualizaciones['is_active'] ?? s.estaActivo,
        'icon_name': actualizaciones.containsKey('icon_name')
            ? actualizaciones['icon_name']
            : s.iconoNombre,
        'icon_color': actualizaciones.containsKey('icon_color')
            ? actualizaciones['icon_color']
            : s.iconoColor,
      });
    }).toList();
    notifyListeners();
  }

  Future<void> eliminarServicio(String id) async {
    await _repo.eliminarServicio(id);
    _servicios = _servicios.where((s) => s.id != id).toList();
    notifyListeners();
  }
}
