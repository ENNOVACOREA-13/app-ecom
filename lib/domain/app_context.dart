import 'package:flutter/material.dart';

class ContextoApp with ChangeNotifier {
  String rol = 'usuario';
  String? empleadoId; // ID del empleado si el usuario es empleado
  int _productosVersion = 0;

  int get productosVersion => _productosVersion;

  void setRol(String nuevoRol) {
    rol = nuevoRol;
    notifyListeners();
  }

  void setEmpleadoId(String? id) {
    empleadoId = id;
    notifyListeners();
  }

  void notificarProductoCreado() {
    _productosVersion++;
    notifyListeners();
  }
}
