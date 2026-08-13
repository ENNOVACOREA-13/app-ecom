import 'package:flutter/material.dart';
import '../data/product_category_repository.dart';
import '../domain/models/product_category.dart';

class ProveedorCategoriasProducto extends ChangeNotifier {
  final _repo = RepositorioCategoriasProducto();

  List<CategoriaProducto> _categorias = [];
  bool _cargando = false;

  List<CategoriaProducto> get categorias => _categorias;
  bool get cargando => _cargando;

  Future<void> cargarCategorias() async {
    _cargando = true;
    notifyListeners();
    try {
      _categorias = await _repo.obtenerCategorias();
    } catch (_) {
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crearCategoria(
      {required String nombre, required String icono, String? imagenUrl}) async {
    try {
      await _repo.crearCategoria(nombre: nombre, icono: icono, imagenUrl: imagenUrl);
      await cargarCategorias();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> actualizarCategoria(String id,
      {required String nombre, required String icono, String? imagenUrl}) async {
    try {
      await _repo.actualizarCategoria(id, nombre: nombre, icono: icono, imagenUrl: imagenUrl);
      await cargarCategorias();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> eliminarCategoria(String id) async {
    try {
      await _repo.eliminarCategoria(id);
      _categorias = _categorias.where((c) => c.id != id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reordenarCategorias(List<CategoriaProducto> nuevoOrden) async {
    _categorias = nuevoOrden;
    notifyListeners();
    await _repo.reordenarCategorias(nuevoOrden.map((c) => c.id).toList());
  }
}
