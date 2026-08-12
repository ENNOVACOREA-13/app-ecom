import 'package:flutter/material.dart';
import '../data/booking_repository.dart';
import '../domain/models/booking.dart';
import '../domain/models/service_model.dart';
import '../domain/models/profile.dart';
import '../domain/models/slot.dart';
import '../domain/enums/booking_status.dart';

class ProveedorReserva extends ChangeNotifier {
  final _repo = RepositorioReserva();

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
      _error = _mapearErrorReserva(e.toString());
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
        precioTotal: totalPrecio,
        idsExtras: _serviciosSeleccionados.skip(1).map((s) => s.id).toList(),
      );
      _creando = false;
      reiniciarFlujo(); // ya llama notifyListeners
      return true;
    } catch (e) {
      _error = _mapearErrorReserva(e.toString());
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
      _error = _mapearErrorReserva(e.toString());
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
      _error = _mapearErrorReserva(e.toString());
    }
    _cargandoReservas = false;
    notifyListeners();
  }

  Future<void> cargarTodasLasReservas({EstadoReserva? estado}) async {
    _cargandoReservas = true;
    notifyListeners();
    try {
      _reservas = await _repo.obtenerTodasLasReservas(estado: estado);
    } catch (e) {
      _error = _mapearErrorReserva(e.toString());
    }
    _cargandoReservas = false;
    notifyListeners();
  }

  // Guarda el último idCliente/idEmpleado para recargar tras cambios
  String? _ultimoIdCliente;
  String? _ultimoIdEmpleado;
  bool _esVistaAdmin = false;

  Future<void> cancelarReserva(String idReserva, String canceladoPor, {String? motivo}) async {
    await _repo.cancelarReserva(idReserva, canceladoPor, motivo);
    // Actualización local optimista
    _reservas = _reservas.map((b) {
      if (b.id != idReserva) return b;
      return Reserva(
        id: b.id, idCliente: b.idCliente, idEmpleado: b.idEmpleado,
        idServicio: b.idServicio, fechaReserva: b.fechaReserva,
        horaInicio: b.horaInicio, horaFin: b.horaFin,
        estado: EstadoReserva.cancelled, precioTotal: b.precioTotal,
        notas: b.notas, creadoEn: b.creadoEn,
        nombreCliente: b.nombreCliente, nombreEmpleado: b.nombreEmpleado,
        nombreServicio: b.nombreServicio, duracionServicio: b.duracionServicio,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> actualizarEstado(String idReserva, EstadoReserva nuevoEstado) async {
    await _repo.actualizarEstado(idReserva, nuevoEstado);
    _reservas = _reservas.map((b) {
      if (b.id != idReserva) return b;
      return Reserva(
        id: b.id, idCliente: b.idCliente, idEmpleado: b.idEmpleado,
        idServicio: b.idServicio, fechaReserva: b.fechaReserva,
        horaInicio: b.horaInicio, horaFin: b.horaFin,
        estado: nuevoEstado, precioTotal: b.precioTotal,
        notas: b.notas, creadoEn: b.creadoEn,
        nombreCliente: b.nombreCliente, nombreEmpleado: b.nombreEmpleado,
        nombreServicio: b.nombreServicio, duracionServicio: b.duracionServicio,
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
      return Reserva(
        id: b.id, idCliente: b.idCliente, idEmpleado: b.idEmpleado,
        idServicio: b.idServicio, fechaReserva: b.fechaReserva,
        horaInicio: b.horaInicio, horaFin: b.horaFin,
        estado: b.estado, precioTotal: b.precioTotal,
        notas: b.notas, creadoEn: b.creadoEn,
        cancelacionSolicitada: true,
        nombreCliente: b.nombreCliente, nombreEmpleado: b.nombreEmpleado,
        nombreServicio: b.nombreServicio, duracionServicio: b.duracionServicio,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> rechazarSolicitudCancelacion(String idReserva) async {
    await _repo.rechazarSolicitudCancelacion(idReserva);
    _reservas = _reservas.map((b) {
      if (b.id != idReserva) return b;
      return Reserva(
        id: b.id, idCliente: b.idCliente, idEmpleado: b.idEmpleado,
        idServicio: b.idServicio, fechaReserva: b.fechaReserva,
        horaInicio: b.horaInicio, horaFin: b.horaFin,
        estado: b.estado, precioTotal: b.precioTotal,
        notas: b.notas, creadoEn: b.creadoEn,
        cancelacionSolicitada: false,
        nombreCliente: b.nombreCliente, nombreEmpleado: b.nombreEmpleado,
        nombreServicio: b.nombreServicio, duracionServicio: b.duracionServicio,
      );
    }).toList();
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  String _mapearErrorReserva(String e) {
    if (e.contains('BOOKING_CONFLICT')) return 'Ese horario ya no está disponible. Elige otro.';
    if (e.contains('DATE_IN_PAST')) return 'No puedes reservar en una fecha pasada.';
    if (e.contains('permission') || e.contains('policy')) return 'No tienes permiso para realizar esta acción.';
    if (e.contains('network') || e.contains('socket')) return 'Sin conexión a internet.';
    if (e.contains('timeout')) return 'La solicitud tardó demasiado. Intenta de nuevo.';
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
}
