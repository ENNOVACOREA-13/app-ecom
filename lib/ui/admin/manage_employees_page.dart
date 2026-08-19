import 'package:flutter/material.dart';
import '../../data/employee_repository.dart';
import '../../data/service_repository.dart';
import '../../data/user_provisioning_service.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/service_model.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

// ─── Modelo interno de día ────────────────────────────────────────────────────
class _DiaHorario {
  final String clave;    // 'monday', 'tuesday', etc.
  final String etiqueta; // 'Lunes', 'Martes', etc.
  TimeOfDay inicio;
  TimeOfDay fin;
  bool activo = true;

  _DiaHorario({
    required this.clave,
    required this.etiqueta,
    required this.inicio,
    required this.fin,
  });
}

// ─── Página principal ─────────────────────────────────────────────────────────

class PaginaGestionEmpleados extends StatefulWidget {
  const PaginaGestionEmpleados({super.key});

  @override
  State<PaginaGestionEmpleados> createState() => _PaginaGestionEmpleadosState();
}

class _PaginaGestionEmpleadosState extends State<PaginaGestionEmpleados>
    with SingleTickerProviderStateMixin {
  final _repo = RepositorioEmpleado();
  final _repoServicio = RepositorioServicio();
  final _servicioAlta = ServicioAltaUsuarios();
  List<Perfil> _usuarios = [];
  bool _cargando = true;
  late TabController _pestanas;

  @override
  void initState() {
    super.initState();
    _pestanas = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _usuarios = await _repo.obtenerTodosLosUsuarios();
    } catch (_) {}
    setState(() => _cargando = false);
  }

  List<Perfil> get _empleados =>
      _usuarios.where((u) => u.rol == RolUsuario.employee).toList();
  List<Perfil> get _clientes =>
      _usuarios.where((u) => u.rol == RolUsuario.client).toList();

  Future<void> _cambiarRol(Perfil usuario, RolUsuario nuevoRol) async {
    await _repo.actualizarRolUsuario(usuario.id, nuevoRol);
    await _cargar();
  }

  Future<void> _alternarActivo(Perfil usuario) async {
    await _repo.alternarActivoUsuario(usuario.id, !usuario.estaActivo);
    await _cargar();
  }

  Future<void> _mostrarHorarios(Perfil empleado) async {
    final horarios = await _repo.obtenerHorarioEmpleado(empleado.id);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _DialogoHorarios(
        empleado: empleado,
        repo: _repo,
        horariosExistentes: horarios,
      ),
    );
  }

  Future<void> _mostrarDiasLibres(Perfil empleado) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _DialogoDiasLibres(
        empleado: empleado,
        repo: _repo,
      ),
    );
  }

  Future<void> _mostrarServicios(Perfil empleado) async {
    final todos = await _repoServicio.obtenerTodosLosServicios();
    final asignados = await _repoServicio.obtenerServiciosPorEmpleado(empleado.id);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => _DialogoServicios(
        empleado: empleado,
        repo: _repoServicio,
        todosLosServicios: todos,
        serviciosAsignadosIds: asignados.map((s) => s.id).toSet(),
      ),
    );
  }

  Future<void> _mostrarDialogoCrearEmpleado() async {
    final ctrlNombre = TextEditingController();
    final ctrlEmail = TextEditingController();
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add_outlined, color: context.colorPrimario, size: 20),
            const SizedBox(width: 8),
            const Text('Nuevo empleado',
                style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 17)),
          ],
        ),
        content: Form(
          key: claveFormulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ctrlNombre,
                style: const TextStyle(color: Color(0xFF1C1C1E)),
                decoration:
                    const InputDecoration(labelText: 'Nombre completo *'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrlEmail,
                style: const TextStyle(color: Color(0xFF1C1C1E)),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Se le manda un correo de invitación para que configure su propia contraseña.',
                style: TextStyle(fontSize: 12, color: kTextSub),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (claveFormulario.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (exito != true || !mounted) return;

    try {
      await _servicioAlta.invitarUsuario(
        email: ctrlEmail.text.trim(),
        fullName: ctrlNombre.text.trim(),
        role: 'employee',
      );
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invitación enviada correctamente'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    ctrlNombre.dispose();
    ctrlEmail.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles'),
        bottom: TabBar(
          controller: _pestanas,
          indicatorColor: context.colorPrimario,
          tabs: [
            Tab(text: 'Empleados (${_empleados.length})'),
            Tab(text: 'Clientes (${_clientes.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_outlined, color: context.colorPrimario),
            tooltip: 'Nuevo empleado',
            onPressed: _mostrarDialogoCrearEmpleado,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: EnvolturaResponsiva(
        child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _pestanas,
              children: [
                _ListaUsuarios(
                  usuarios: _empleados,
                  alCambiarRol: _cambiarRol,
                  alAlternar: _alternarActivo,
                  alVerHorarios: _mostrarHorarios,
                  alVerServicios: _mostrarServicios,
                  alVerDiasLibres: _mostrarDiasLibres,
                ),
                _ListaUsuarios(
                  usuarios: _clientes,
                  alCambiarRol: _cambiarRol,
                  alAlternar: _alternarActivo,
                ),
              ],
            ),
      ),
    );
  }
}

// ─── Diálogo de horarios ──────────────────────────────────────────────────────

class _DialogoHorarios extends StatefulWidget {
  final Perfil empleado;
  final RepositorioEmpleado repo;
  final List<Map<String, dynamic>> horariosExistentes;

  const _DialogoHorarios({
    required this.empleado,
    required this.repo,
    required this.horariosExistentes,
  });

  @override
  State<_DialogoHorarios> createState() => _DialogoHorariosState();
}

class _DialogoHorariosState extends State<_DialogoHorarios> {
  late List<_DiaHorario> _dias;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _dias = [
      _DiaHorario(clave: 'monday',    etiqueta: 'Lunes',      inicio: const TimeOfDay(hour: 11, minute: 0), fin: const TimeOfDay(hour: 20, minute: 0)),
      _DiaHorario(clave: 'tuesday',   etiqueta: 'Martes',     inicio: const TimeOfDay(hour: 11, minute: 0), fin: const TimeOfDay(hour: 20, minute: 0)),
      _DiaHorario(clave: 'wednesday', etiqueta: 'Miércoles',  inicio: const TimeOfDay(hour: 11, minute: 0), fin: const TimeOfDay(hour: 20, minute: 0)),
      _DiaHorario(clave: 'thursday',  etiqueta: 'Jueves',     inicio: const TimeOfDay(hour: 11, minute: 0), fin: const TimeOfDay(hour: 20, minute: 0)),
      _DiaHorario(clave: 'friday',    etiqueta: 'Viernes',    inicio: const TimeOfDay(hour: 11, minute: 0), fin: const TimeOfDay(hour: 20, minute: 0)),
      _DiaHorario(clave: 'saturday',  etiqueta: 'Sábado',     inicio: const TimeOfDay(hour: 11, minute: 0), fin: const TimeOfDay(hour: 20, minute: 0)),
      _DiaHorario(clave: 'sunday',    etiqueta: 'Domingo',    inicio: const TimeOfDay(hour: 11, minute: 0), fin: const TimeOfDay(hour: 18, minute: 0)),
    ];

    // Sobreescribir con datos existentes de la BD
    for (final h in widget.horariosExistentes) {
      final clave = h['day_of_week'] as String;
      final idx = _dias.indexWhere((d) => d.clave == clave);
      if (idx == -1) continue;
      final ini = _parsearHora(h['start_time'] as String);
      final fin = _parsearHora(h['end_time'] as String);
      if (ini != null) _dias[idx].inicio = ini;
      if (fin != null) _dias[idx].fin = fin;
      _dias[idx].activo = (h['is_active'] as bool?) ?? true;
    }
  }

  TimeOfDay? _parsearHora(String hora) {
    final partes = hora.split(':');
    if (partes.length < 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _elegirHora(_DiaHorario dia, bool esInicio) async {
    final actual = esInicio ? dia.inicio : dia.fin;
    final sel = await showTimePicker(
      context: context,
      initialTime: actual,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (sel != null) {
      setState(() {
        if (esInicio) dia.inicio = sel;
        else dia.fin = sel;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      for (final dia in _dias) {
        if (!dia.activo) continue;
        await widget.repo.upsertDiaHorario(
          idEmpleado: widget.empleado.id,
          diaSemana: dia.clave,
          horaInicio: _fmt(dia.inicio),
          horaFin: _fmt(dia.fin),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Horarios guardados'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.schedule, color: context.colorPrimario, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.empleado.nombreCompleto,
              style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _dias.map((dia) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      dia.etiqueta,
                      style: TextStyle(
                        color: dia.activo
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFC7C7CC),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: dia.activo,
                    activeColor: context.colorPrimario,
                    onChanged: (v) => setState(() => dia.activo = v),
                  ),
                  if (dia.activo) ...[
                    _BtnHora(
                      hora: _fmt(dia.inicio),
                      onTap: () => _elegirHora(dia, true),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('–', style: TextStyle(color: Color(0xFFC7C7CC))),
                    ),
                    _BtnHora(
                      hora: _fmt(dia.fin),
                      onTap: () => _elegirHora(dia, false),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// ─── Diálogo de días libres puntuales ──────────────────────────────────────────

class _DialogoDiasLibres extends StatefulWidget {
  final Perfil empleado;
  final RepositorioEmpleado repo;

  const _DialogoDiasLibres({required this.empleado, required this.repo});

  @override
  State<_DialogoDiasLibres> createState() => _DialogoDiasLibresState();
}

class _DialogoDiasLibresState extends State<_DialogoDiasLibres> {
  List<Map<String, dynamic>> _diasLibres = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _diasLibres = await widget.repo.obtenerDiasLibres(widget.empleado.id);
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _agregar() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 1)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 180)),
    );
    if (fecha == null || !mounted) return;
    try {
      await widget.repo.agregarDiaLibre(idEmpleado: widget.empleado.id, fecha: fecha);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminar(String id) async {
    try {
      await widget.repo.eliminarDiaLibre(id);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.event_busy_outlined, color: context.colorPrimario, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.empleado.nombreCompleto,
              style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: _cargando
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            : _diasLibres.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Sin días libres marcados',
                        style: TextStyle(color: kTextSub)),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _diasLibres.map((d) {
                      final fecha = DateTime.parse(d['date'] as String);
                      final texto =
                          '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(texto,
                                  style: const TextStyle(
                                      color: Color(0xFF1C1C1E), fontSize: 13)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () => _eliminar(d['id'] as String),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: _agregar,
          child: const Text('Agregar día'),
        ),
      ],
    );
  }
}

// ─── Diálogo de servicios que puede realizar el empleado ──────────────────────

class _DialogoServicios extends StatefulWidget {
  final Perfil empleado;
  final RepositorioServicio repo;
  final List<ModeloServicio> todosLosServicios;
  final Set<String> serviciosAsignadosIds;

  const _DialogoServicios({
    required this.empleado,
    required this.repo,
    required this.todosLosServicios,
    required this.serviciosAsignadosIds,
  });

  @override
  State<_DialogoServicios> createState() => _DialogoServiciosState();
}

class _DialogoServiciosState extends State<_DialogoServicios> {
  late Set<String> _seleccionados;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _seleccionados = {...widget.serviciosAsignadosIds};
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final originales = widget.serviciosAsignadosIds;
      final aAgregar = _seleccionados.difference(originales);
      final aQuitar = originales.difference(_seleccionados);

      for (final idServicio in aAgregar) {
        await widget.repo.asignarServicioAEmpleado(widget.empleado.id, idServicio);
      }
      for (final idServicio in aQuitar) {
        await widget.repo.quitarServicioDeEmpleado(widget.empleado.id, idServicio);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Servicios actualizados'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.content_cut, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.empleado.nombreCompleto,
              style: const TextStyle(
                  color: Color(0xFF1C1C1E), fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.todosLosServicios.isEmpty
            ? const Text('No hay servicios creados todavía.',
                style: TextStyle(color: Color(0xFF8E8E93)))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.todosLosServicios.map((s) {
                    final marcado = _seleccionados.contains(s.id);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          value: marcado,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _seleccionados.add(s.id);
                            } else {
                              _seleccionados.remove(s.id);
                            }
                          }),
                          activeColor: color,
                          checkColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFAEAEB2), width: 1.5),
                          tileColor: Colors.white,
                          selectedTileColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(s.nombre,
                              style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${s.etiquetaDuracion} · \$${s.precio.toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                        ),
                        const Divider(height: 1, color: Color(0xFFE5E5EA)),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8E8E93))),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _BtnHora extends StatelessWidget {
  final String hora;
  final VoidCallback onTap;
  const _BtnHora({required this.hora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(hora, style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 13)),
      ),
    );
  }
}

// ─── Lista de usuarios ────────────────────────────────────────────────────────

class _ListaUsuarios extends StatelessWidget {
  final List<Perfil> usuarios;
  final Future<void> Function(Perfil, RolUsuario) alCambiarRol;
  final Future<void> Function(Perfil) alAlternar;
  final Future<void> Function(Perfil)? alVerHorarios;
  final Future<void> Function(Perfil)? alVerServicios;
  final Future<void> Function(Perfil)? alVerDiasLibres;

  const _ListaUsuarios({
    required this.usuarios,
    required this.alCambiarRol,
    required this.alAlternar,
    this.alVerHorarios,
    this.alVerServicios,
    this.alVerDiasLibres,
  });

  @override
  Widget build(BuildContext context) {
    if (usuarios.isEmpty) {
      return const EstadoVacio(icono: Icons.people_outline, titulo: 'Sin usuarios');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final usuario = usuarios[i];
        final esEmpleado = usuario.rol == RolUsuario.employee;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Row(
            children: [
              AvatarRed(
                  url: usuario.urlAvatar,
                  nombre: usuario.nombreCompleto,
                  radio: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: TextStyle(
                        color: usuario.estaActivo
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFAEAEB2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      usuario.rol.toDbString(),
                      style:
                          const TextStyle(color: kTextSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: kTextSub),
                color: Colors.white,
                itemBuilder: (_) {
                  final items = <PopupMenuEntry<String>>[];

                  if (esEmpleado && alVerHorarios != null) {
                    items.add(PopupMenuItem<String>(
                      value: 'horarios',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: context.colorPrimario, size: 18),
                          const SizedBox(width: 8),
                          const Text('Horarios',
                              style: TextStyle(color: Color(0xFF1C1C1E))),
                        ],
                      ),
                    ));
                  }

                  if (esEmpleado && alVerServicios != null) {
                    items.add(PopupMenuItem<String>(
                      value: 'servicios',
                      child: Row(
                        children: [
                          Icon(Icons.content_cut, color: context.colorPrimario, size: 18),
                          const SizedBox(width: 8),
                          const Text('Servicios',
                              style: TextStyle(color: Color(0xFF1C1C1E))),
                        ],
                      ),
                    ));
                  }

                  if (esEmpleado && alVerDiasLibres != null) {
                    items.add(PopupMenuItem<String>(
                      value: 'dias_libres',
                      child: Row(
                        children: [
                          Icon(Icons.event_busy_outlined, color: context.colorPrimario, size: 18),
                          const SizedBox(width: 8),
                          const Text('Días libres',
                              style: TextStyle(color: Color(0xFF1C1C1E))),
                        ],
                      ),
                    ));
                  }

                  if (!esEmpleado) {
                    items.add(const PopupMenuItem<String>(
                      value: 'make_employee',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: kTextSub, size: 18),
                          SizedBox(width: 8),
                          Text('Hacer empleado',
                              style: TextStyle(color: kTextSub)),
                        ],
                      ),
                    ));
                  } else {
                    items.add(const PopupMenuItem<String>(
                      value: 'make_client',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: kTextSub, size: 18),
                          SizedBox(width: 8),
                          Text('Hacer cliente',
                              style: TextStyle(color: kTextSub)),
                        ],
                      ),
                    ));
                  }

                  items.add(PopupMenuItem<String>(
                    value: 'toggle_active',
                    child: Row(
                      children: [
                        Icon(
                          usuario.estaActivo
                              ? Icons.power_settings_new_rounded
                              : Icons.check_circle_outline_rounded,
                          color: usuario.estaActivo ? Colors.red : Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          usuario.estaActivo ? 'Desactivar' : 'Activar',
                          style: TextStyle(
                              color: usuario.estaActivo ? Colors.red : Colors.green),
                        ),
                      ],
                    ),
                  ));

                  return items;
                },
                onSelected: (action) {
                  switch (action) {
                    case 'horarios':
                      alVerHorarios?.call(usuario);
                      break;
                    case 'servicios':
                      alVerServicios?.call(usuario);
                      break;
                    case 'dias_libres':
                      alVerDiasLibres?.call(usuario);
                      break;
                    case 'make_employee':
                      alCambiarRol(usuario, RolUsuario.employee);
                      break;
                    case 'make_client':
                      alCambiarRol(usuario, RolUsuario.client);
                      break;
                    case 'toggle_active':
                      alAlternar(usuario);
                      break;
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
