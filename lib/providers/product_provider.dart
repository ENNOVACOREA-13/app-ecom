import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../domain/models/product.dart';

/// Traduce un error crudo (excepción de Supabase/RPC) a un mensaje que el
/// usuario entienda, sin exponer detalles internos del servidor.
String mapearErrorProducto(String e) {
  final eMin = e.toLowerCase();
  if (eMin.contains('permission') || eMin.contains('policy')) return 'No tienes permiso para realizar esta acción.';
  if (eMin.contains('network') || eMin.contains('socket')) return 'Sin conexión a internet.';
  if (eMin.contains('timeout')) return 'La solicitud tardó demasiado. Intenta de nuevo.';
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
}

class ProveedorProducto extends ChangeNotifier {
  final _repo = RepositorioProducto();

  List<Producto> _productos = [];
  bool _cargando = false;
  String? _error;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarProductos({bool esVistaAdmin = false}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _productos = esVistaAdmin ? await _repo.obtenerTodosLosProductos() : await _repo.obtenerProductosActivos();
    } catch (e) {
      _error = mapearErrorProducto(e.toString());
    }
    _cargando = false;
    notifyListeners();
  }

  Future<bool> crearProducto({
    required String nombre,
    String? descripcion,
    required double precio,
    double? precioOferta,
    required int existencias,
    required String creadoPor,
    String? urlImagen,
  }) async {
    try {
      final producto = await _repo.crearProducto(
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        precioOferta: precioOferta,
        existencias: existencias,
        creadoPor: creadoPor,
        urlImagen: urlImagen,
      );
      _productos.insert(0, producto);
      notifyListeners();
      return true;
    } catch (e) {
      _error = mapearErrorProducto(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> actualizarProducto(String id, Map<String, dynamic> actualizaciones) async {
    await _repo.actualizarProducto(id, actualizaciones);
    await cargarProductos(esVistaAdmin: true);
  }

  Future<void> eliminarProducto(String id) async {
    await _repo.eliminarProducto(id);
    _productos = _productos.where((p) => p.id != id).toList();
    notifyListeners();
  }

}
