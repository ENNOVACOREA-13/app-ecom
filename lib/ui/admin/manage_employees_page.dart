import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../data/employee_repository.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/models/profile.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

// ─── Modelo interno de día ────────────────────────────────────────────────────
class _DiaHorario {
  final String clave;    // 'monday', 'tuesday', etc.
  final String etiqueta; // 'Lunes', 'Martes', etc.
  TimeOfDay inicio;
  TimeOfDay fin;
  bool activo;

  _DiaHorario({
    required this.clave,
    required this.etiqueta,
    required this.inicio,
    required this.fin,
    this.activo = true,
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

  Future<void> _mostrarDialogoCrearEmpleado() async {
    final ctrlNombre = TextEditingController();
    final ctrlEmail = TextEditingController();
    final ctrlContrasena = TextEditingController();
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_outlined, color: kPrimary, size: 20),
            SizedBox(width: 8),
            Text('Nuevo empleado',
                style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: Form(
          key: claveFormulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: ctrlNombre,
                style: const TextStyle(color: Colors.white),
                decoration:
                    const InputDecoration(labelText: 'Nombre completo *'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrlEmail,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrlContrasena,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Contraseña temporal *'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
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
      final respuesta = await http.post(
        Uri.parse('$kSupabaseUrl/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': kSupabaseAnonKey,
        },
        body: jsonEncode({
          'email': ctrlEmail.text.trim(),
          'password': ctrlContrasena.text,
          'data': {
            'full_name': ctrlNombre.text.trim(),
            'role': 'employee',
          },
        }),
      );

      final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (respuesta.statusCode == 200 && cuerpo['id'] != null) {
        final idUsuario = cuerpo['id'] as String;
        await _repo.actualizarRolUsuario(idUsuario, RolUsuario.employee);
        await _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Empleado creado correctamente'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        throw cuerpo['msg'] ?? cuerpo['message'] ?? 'Error desconocido';
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
    ctrlContrasena.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Empleados'),
        bottom: TabBar(
          controller: _pestanas,
          indicatorColor: kPrimary,
          tabs: [
            Tab(text: 'Empleados (${_empleados.length})'),
            Tab(text: 'Clientes (${_clientes.length})'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearEmpleado,
        backgroundColor: kPrimary,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Empleado'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _pestanas,
              children: [
                _ListaUsuarios(
                  usuarios: _empleados,
                  alCambiarRol: _cambiarRol,
                  alAlternar: _alternarActivo,
                  alVerHorarios: _mostrarHorarios,
                ),
                _ListaUsuarios(
                  usuarios: _clientes,
                  alCambiarRol: _cambiarRol,
                  alAlternar: _alternarActivo,
                ),
              ],
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
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.schedule, color: kPrimary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.empleado.nombreCompleto,
              style: const TextStyle(color: Colors.white, fontSize: 15),
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
                        color: dia.activo ? Colors.white : Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: dia.activo,
                    activeColor: kPrimary,
                    onChanged: (v) => setState(() => dia.activo = v),
                  ),
                  if (dia.activo) ...[
                    _BtnHora(
                      hora: _fmt(dia.inicio),
                      onTap: () => _elegirHora(dia, true),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('–', style: TextStyle(color: Colors.white38)),
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
          color: kSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(hora, style: const TextStyle(color: Colors.white, fontSize: 13)),
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

  const _ListaUsuarios({
    required this.usuarios,
    required this.alCambiarRol,
    required this.alAlternar,
    this.alVerHorarios,
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
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kDivider),
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
                        color: usuario.estaActivo ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      usuario.rol.toDbString(),
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white38),
                color: kCard,
                itemBuilder: (_) {
                  final items = <PopupMenuEntry<String>>[];

                  if (esEmpleado && alVerHorarios != null) {
                    items.add(const PopupMenuItem<String>(
                      value: 'horarios',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: kPrimary, size: 18),
                          SizedBox(width: 8),
                          Text('Horarios',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ));
                  }

                  if (!esEmpleado) {
                    items.add(const PopupMenuItem<String>(
                      value: 'make_employee',
                      child: Text('Hacer empleado',
                          style: TextStyle(color: Colors.white)),
                    ));
                  } else {
                    items.add(const PopupMenuItem<String>(
                      value: 'make_client',
                      child: Text('Hacer cliente',
                          style: TextStyle(color: Colors.white)),
                    ));
                  }

                  items.add(PopupMenuItem<String>(
                    value: 'toggle_active',
                    child: Text(
                      usuario.estaActivo ? 'Desactivar' : 'Activar',
                      style: TextStyle(
                          color: usuario.estaActivo
                              ? Colors.red
                              : Colors.green),
                    ),
                  ));

                  return items;
                },
                onSelected: (action) {
                  switch (action) {
                    case 'horarios':
                      alVerHorarios?.call(usuario);
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
