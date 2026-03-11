import 'package:flutter/material.dart';
import '../data/config_repository.dart';
import '../core/theme/app_theme.dart';

class ProveedorConfig extends ChangeNotifier {
  final _repo = RepositorioConfig();
  Color _colorPrimario = kPrimary;

  Color get colorPrimario => _colorPrimario;

  Future<void> cargar() async {
    final color = await _repo.obtenerColorPrimario();
    if (color != null && color != _colorPrimario) {
      _colorPrimario = color;
      notifyListeners();
    }
  }

  Future<bool> actualizarColor(Color color) async {
    final exito = await _repo.actualizarColorPrimario(color);
    if (exito) {
      _colorPrimario = color;
      notifyListeners();
    }
    return exito;
  }
}
