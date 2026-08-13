import 'package:flutter/material.dart';
import '../domain/models/product.dart';

class ItemCarrito {
  final Producto producto;
  int cantidad;
  ItemCarrito({required this.producto, this.cantidad = 1});
  double get subtotal => producto.precio * cantidad;
}

class ProveedorCarrito extends ChangeNotifier {
  final List<ItemCarrito> _items = [];

  List<ItemCarrito> get items => List.unmodifiable(_items);
  int get totalItems => _items.fold(0, (s, i) => s + i.cantidad);
  double get total => _items.fold(0.0, (s, i) => s + i.subtotal);
  bool get vacio => _items.isEmpty;

  /// Agrega [cantidad] unidades del producto sin superar el stock disponible.
  /// Devuelve `false` si ya se había alcanzado el máximo y no se agregó nada.
  bool agregar(Producto producto, {int cantidad = 1}) {
    final idx = _items.indexWhere((i) => i.producto.id == producto.id);
    final actual = idx >= 0 ? _items[idx].cantidad : 0;
    final nuevaCantidad = (actual + cantidad).clamp(0, producto.existencias);
    if (nuevaCantidad <= actual) return false;
    if (idx >= 0) {
      _items[idx].cantidad = nuevaCantidad;
    } else {
      _items.add(ItemCarrito(producto: producto, cantidad: nuevaCantidad));
    }
    notifyListeners();
    return true;
  }

  void decrementar(String productoId) {
    final idx = _items.indexWhere((i) => i.producto.id == productoId);
    if (idx >= 0) {
      if (_items[idx].cantidad > 1) {
        _items[idx].cantidad--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void quitar(String productoId) {
    _items.removeWhere((i) => i.producto.id == productoId);
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }

  bool contiene(String productoId) => _items.any((i) => i.producto.id == productoId);

  int cantidadProducto(String productoId) {
    final item = _items.where((i) => i.producto.id == productoId).firstOrNull;
    return item?.cantidad ?? 0;
  }
}
