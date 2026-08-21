import 'package:flutter/material.dart';
import '../data/booking_repository.dart';
import '../domain/models/booking.dart';
import '../domain/models/service_model.dart';
import '../domain/models/profile.dart';
import '../domain/models/slot.dart';
import '../domain/enums/booking_status.dart';

/// Traduce un error crudo (excepción de Supabase/RPC) a un mensaje que el
/// usuario entienda, sin exponer detalles internos del servidor.
String mapearErrorReserva(String e) {
  if (e.contains('BOOKING_CONFLICT')) return 'Ese horario ya no está disponible. Elige otro.';
  if (e.contains('DATE_IN_PAST')) return 'No puedes reservar en una fecha pasada.';
  final eMin = e.toLowerCase();
  if (eMin.contains('permission') || eMin.contains('policy')) return 'No tienes permiso para realizar esta acción.';
  if (eMin.contains('network') || eMin.contains('socket')) return 'Sin conexión a internet.';
  if (eMin.contains('timeout')) return 'La solicitud tardó demasiado. Intenta de nuevo.';
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
}

class ProveedorReserva extends ChangeNotifier {
  ProveedorReserva({RepositorioReserva? repo}) : _repo = repo ?? RepositorioReserva();

  static const _tamanoPaginaAdmin = 100;

  final RepositorioReserva _repo;

  // Flujo de creación de reserva
  List<ModeloServicio> _serviciosSeleccionados = [];
  Perfil? _empleadoSeleccionado;
  DateTime? _fechaSeleccionada;
  Turno? _turnoSeleccionado;

  // Datos cargados
  List<Reserva> _reservas = [];
  List<Turno> _turnos = [];
  bool _cargandoTurnos = false;
  bool _cargandoReservas = false;
  bool _cargandoMasReservas = false;
  bool _hayMasReservasAdmin = true;
  EstadoReserva? _estadoTodasReservas;
  bool _creando = false;
  String? _error;

  // Getters flujo
  ModeloServicio? get servicioSeleccionado =>
      _serviciosSeleccionados.isNotEmpty ? _serviciosSeleccionados.first : null;
  List<ModeloServicio> get serviciosSeleccionados => _serviciosSeleccionados;
  int get totalDuracionMin =>
      _serviciosSeleccionados.fold(0, (sum, s) => sum + s.duracionMin);
  double get totalPrecio =>
      _serviciosSeleccionados.fold(0.0, (sum, s) => sum + s.precio);
  Perfil? get empleadoSeleccionado => _empleadoSeleccionado;
  DateTime? get fechaSeleccionada => _fechaSeleccionada;
  Turno? get turnoSeleccionado => _turnoSeleccionado;

  // Getters datos
  List<Reserva> get reservas => _reservas;
  List<Turno> get turnos => _turnos;
  bool get cargandoTurnos => _cargandoTurnos;
  bool get cargandoReservas => _cargandoReservas;
  bool get cargandoMasReservas => _cargandoMasReservas;
  bool get hayMasReservasAdmin => _hayMasReservasAdmin;
  bool get creando => _creando;
  String? get error => _error;

  // ── Flujo de selección ──────────────────────────────────────

  /// Solo se puede elegir un servicio por reserva: tocar uno nuevo reemplaza
  /// la selección; tocar el ya seleccionado lo deselecciona.
  void seleccionarServicio(ModeloServicio servicio) {
    final yaSeleccionado = _serviciosSeleccionados.any((s) => s.id == servicio.id);
    _empleadoSeleccionado = null;
    _turnoSeleccionado = null;
    _serviciosSeleccionados = yaSeleccionado ? [] : [servicio];
    notifyListeners();
  }

  void seleccionarEmpleado(Perfil empleado) {
    _empleadoSeleccionado = empleado;
    _turnoSeleccionado = null;
    notifyListeners();
  }

  void seleccionarFecha(DateTime fecha) {
    _fechaSeleccionada = fecha;
    _turnoSeleccionado = null;
    _turnos = [];
    notifyListeners();
  }

  void seleccionarTurno(Turno turno) {
    _turnoSeleccionado = turno;
    notifyListeners();
  }

  void reiniciarFlujo() {
    _serviciosSeleccionados = [];
    _empleadoSeleccionado = null;
    _fechaSeleccionada = null;
    _turnoSeleccionado = null;
    _turnos = [];
    _error = null;
    notifyListeners();
  }

  // ── Slots disponibles ────────────────────────────────────────

  Future<void> cargarTurnos() async {
    if (_empleadoSeleccionado == null ||
        _fechaSeleccionada == null ||
        _serviciosSeleccionados.isEmpty) return;
    _cargandoTurnos = true;
    _turnos = [];
    _error = null;
    notifyListeners();
    try {
      _turnos = await _repo.obtenerTurnosDisponibles(
        idEmpleado: _empleadoSeleccionado!.id,
        fecha: _fechaSeleccionada!,
        duracionMin: totalDuracionMin,
      );
      _cargandoTurnos = false;
      notifyListeners();
    } catch (e) {
      _error = mapearErrorReserva(e.toString());
      _cargandoTurnos = false;
      notifyListeners();
    }
  }

  // ── Crear reserva ────────────────────────────────────────────

  Future<bool> crearReserva(String idCliente) async {
    if (_serviciosSeleccionados.isEmpty ||
        _empleadoSeleccionado == null ||
        _fechaSeleccionada == null ||
        _turnoSeleccionado == null) return false;

    _creando = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.crearReserva(
        idCliente: idCliente,
        idEmpleado: _empleadoSeleccionado!.id,
        idServicio: _serviciosSeleccionados.first.id,
        fecha: _fechaSeleccionada!,
        horaInicio: _turnoSeleccionado!.inicio,
        idsExtras: _serviciosSeleccionados.skip(1).map((s) => s.id).toList(),
      );
      _creando = false;
      reiniciarFlujo(); // ya llama notifyListeners
      // "Mis Reservas" vive en un IndexedStack (pestaña ya construida) y
      // solo carga su lista una vez en initState — sin este refresh acá,
      // la reserva nueva quedaba invisible hasta reiniciar el navegador,
      // aunque ya estuviera guardada de verdad (bug real 2026-08-21). La
      // reserva YA se creó con éxito en este punto, así que si el refresh
      // en sí falla no debe convertirse en un error para el usuario —
      // cargarReservasCliente ya atrapa sus propios errores, solo se
      // limpia _error por si acaso para no arrastrar ese fallo aparte.
      await cargarReservasCliente(idCliente);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = mapearErrorReserva(e.toString());
      _creando = false;
      notifyListeners();
      return false;
    }
  }

  // ── Cargar reservas ──────────────────────────────────────────

  Future<void> cargarReservasCliente(String idCliente) async {
    _cargandoReservas = true;
    notifyListeners();
    try {
      _reservas = await _repo.obtenerReservasCliente(idCliente);
    } catch (e) {
      _error = mapearErrorReserva(e.toString());
    }
    _cargandoReservas = false;
    notifyListeners();
  }

  Future<void> cargarReservasEmpleado(String idEmpleado) async {
    _cargandoReservas = true;
    notifyListeners();
    try {
      _reservas = await _repo.obtenerReservasEmpleado(idEmpleado);
    } catch (e) {
      _error = mapearErrorReserva(e.toString());
    }
    _cargandoReservas = false;
    notifyListeners();
  }

  Future<void> cargarTodasLasReservas({EstadoReserva? estado}) async {
    _cargandoReservas = true;
    _estadoTodasReservas = estado;
    notifyListeners();
    try {
      final pagina = await _repo.obtenerTodasLasReservas(
          estado: estado, desde: 0, cantidad: _tamanoPaginaAdmin);
      _reservas = pagina;
      _hayMasReservasAdmin = pagina.length == _tamanoPaginaAdmin;
    } catch (e) {
      _error = mapearErrorReserva(e.toString());
    }
    _cargandoReservas = false;
    notifyListeners();
  }

  Future<void> cargarMasReservas() async {
    if (_cargandoMasReservas || !_hayMasReservasAdmin) return;
    _cargandoMasReservas = true;
    notifyListeners();
    try {
      final pagina = await _repo.obtenerTodasLasReservas(
        estado: _estadoTodasReservas,
        desde: _reservas.length,
        cantidad: _tamanoPaginaAdmin,
      );
      _reservas = [..._reservas, ...pagina];
      _hayMasReservasAdmin = pagina.length == _tamanoPaginaAdmin;
    } catch (e) {
      _error = mapearErrorReserva(e.toString());
    }
    _cargandoMasReservas = false;
    notifyListeners();
  }

  Future<void> cancelarReserva(String idReserva, String canceladoPor, {String? motivo}) async {
    await _repo.cancelarReserva(idReserva, canceladoPor, motivo);
    // Actualización local optimista
    _reservas = _reservas.map((b) {
      if (b.id != idReserva) return b;
      return b.copyWith(estado: EstadoReserva.cancelled);
    }).toList();
    notifyListeners();
  }

  Future<void> actualizarEstado(String idReserva, EstadoReserva nuevoEstado) async {
    await _repo.actualizarEstado(idReserva, nuevoEstado);
    _reservas = _reservas.map((b) {
      if (b.id != idReserva) return b;
      return b.copyWith(
        estado: nuevoEstado,
        fechaPago: nuevoEstado == EstadoReserva.completed ? (b.fechaPago ?? DateTime.now()) : b.fechaPago,
      );
    }).toList();
    notifyListeners();
  }

  /// Fetch fresco (sin caché local) para validar un QR justo antes de escanear.
  Future<Reserva?> obtenerReservaPorId(String id) => _repo.obtenerReservaPorId(id);

  Future<void> solicitarCancelacion(String idReserva) async {
    await _repo.solicitarCancelacion(idReserva);
    _reservas = _reservas.map((b) {
      if (b.id != idReserva) return b;
      return b.copyWith(cancelacionSolicitada: true);
    }).toList();
    notifyListeners();
  }

  Future<void> rechazarSolicitudCancelacion(String idReserva) async {
    await _repo.rechazarSolicitudCancelacion(idReserva);
    _reservas = _reservas.map((b) {
      if (b.id != idReserva) return b;
      return b.copyWith(cancelacionSolicitada: false);
    }).toList();
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

}
