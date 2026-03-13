import 'package:flutter/material.dart';
import '../data/commission_repository.dart';
import '../domain/models/commission_model.dart';

class ProveedorComision extends ChangeNotifier {
  final _repo = RepositorioComision();

  List<ConfigComision> configuraciones = [];
  AjustesComision? ajustes;
  List<EntradaComision> entradasSemana = [];
  List<CorteComision> cortes = [];
  List<Map<String, dynamic>> resumenAdmin = [];
  bool cargando = false;
  String? error;

  // ── Admin: cargar todo ──────────────────────────────────────

  Future<void> cargarAdmin() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _repo.obtenerConfiguraciones(),
        _repo.obtenerAjustes(),
        _repo.obtenerTodosLosCortes(),
        _repo.obtenerResumenSemanaActual(),
      ]);
      configuraciones = resultados[0] as List<ConfigComision>;
      ajustes = resultados[1] as AjustesComision?;
      cortes = resultados[2] as List<CorteComision>;
      resumenAdmin = resultados[3] as List<Map<String, dynamic>>;
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  // ── Empleado: cargar semana actual ────────────────────────────

  Future<void> cargarSemanaEmpleado(String empleadoId) async {
    cargando = true;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _repo.obtenerEntradaSemanaActual(empleadoId),
        _repo.obtenerCortesEmpleado(empleadoId),
      ]);
      entradasSemana = resultados[0] as List<EntradaComision>;
      cortes = resultados[1] as List<CorteComision>;
    } catch (_) {}
    cargando = false;
    notifyListeners();
  }

  // ── Configurar porcentaje por servicio ────────────────────────

  Future<void> guardarConfiguracion(String servicioId, double monto) async {
    try {
      await _repo.guardarConfiguracion(servicioId, monto);
      final idx = configuraciones.indexWhere((c) => c.servicioId == servicioId);
      if (idx >= 0) {
        configuraciones[idx] = ConfigComision(
            id: configuraciones[idx].id,
            servicioId: servicioId,
            monto: monto);
      } else {
        configuraciones = await _repo.obtenerConfiguraciones();
      }
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> eliminarConfiguracion(String servicioId) async {
    try {
      await _repo.eliminarConfiguracion(servicioId);
      configuraciones.removeWhere((c) => c.servicioId == servicioId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Ajustes de cierre ─────────────────────────────────────────

  Future<void> guardarAjustes({
    required int diaCierre,
    required int horaCierre,
    required int minutoCierre,
  }) async {
    if (ajustes == null) return;
    try {
      await _repo.guardarAjustes(
        id: ajustes!.id,
        diaCierre: diaCierre,
        horaCierre: horaCierre,
        minutoCierre: minutoCierre,
      );
      ajustes = AjustesComision(
          id: ajustes!.id,
          diaCierre: diaCierre,
          horaCierre: horaCierre,
          minutoCierre: minutoCierre);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Procesar corte ────────────────────────────────────────────

  Future<void> procesarCorte(DateTime inicioSemana, DateTime finSemana) async {
    cargando = true;
    notifyListeners();
    try {
      await _repo.procesarCorte(inicioSemana, finSemana);
      await cargarAdmin();
    } catch (e) {
      error = e.toString();
      cargando = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> marcarCortePagado(String corteId, {String? notas}) async {
    try {
      await _repo.marcarCortePagado(corteId, notas: notas);
      final idx = cortes.indexWhere((c) => c.id == corteId);
      if (idx >= 0) {
        final c = cortes[idx];
        cortes[idx] = CorteComision(
          id: c.id,
          empleadoId: c.empleadoId,
          nombreEmpleado: c.nombreEmpleado,
          inicioSemana: c.inicioSemana,
          finSemana: c.finSemana,
          montoTotal: c.montoTotal,
          cantidadServicios: c.cantidadServicios,
          estado: 'paid',
          notas: notas ?? c.notas,
          creadoEl: c.creadoEl,
        );
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  double get totalSemanaEmpleado =>
      entradasSemana.fold(0, (s, e) => s + e.monto);

  int get serviciosSemanaEmpleado => entradasSemana.length;

  double montoPorServicio(String servicioId) {
    try {
      return configuraciones.firstWhere((c) => c.servicioId == servicioId).monto;
    } catch (_) {
      return 0;
    }
  }
}
