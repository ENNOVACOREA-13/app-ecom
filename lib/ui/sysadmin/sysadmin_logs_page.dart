import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../data/activity_service.dart';
import '../common/app_widgets.dart';
import '../common/toast.dart';

class PaginaLogs extends StatefulWidget {
  const PaginaLogs({super.key});

  @override
  State<PaginaLogs> createState() => _PaginaLogsState();
}

class _PaginaLogsState extends State<PaginaLogs>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _client = Supabase.instance.client;

  static const _tamanoPagina = 100;

  List<Map<String, dynamic>> _sesiones = [];
  List<Map<String, dynamic>> _actividad = [];
  bool _cargandoSesiones = true;
  bool _cargandoActividad = true;
  bool _cargandoMasSesiones = false;
  bool _cargandoMasActividad = false;
  bool _haySesionesRestantes = true;
  bool _hayActividadRestante = true;
  String _filtroEvento = 'todos';
  String _filtroSesion = 'todas'; // todas | activas | cerradas

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cargarSesiones();
    _cargarActividad();
    ServicioActividad.instancia.registrarPantalla('SysAdmin_Logs');
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _borrarSesionesCerradas() async {
    final cantidad = _totalCerradas;
    if (cantidad == 0) {
      mostrarToast(context, 'No hay sesiones cerradas para borrar', tipo: TipoToast.info);
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar sesiones cerradas'),
        content: Text(
            '¿Eliminar $cantidad sesiones cerradas? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar todas'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      // Obtener IDs de sesiones cerradas
      final cerradas = await _client
          .from('session_logs')
          .select('id')
          .eq('is_active', false);
      final ids = (cerradas as List)
          .map((s) => s['id'] as String)
          .toList();

      if (ids.isNotEmpty) {
        // Borrar activity_logs asociados primero (foreign key)
        await _client
            .from('activity_logs')
            .delete()
            .inFilter('session_id', ids);

        // Ahora borrar las sesiones cerradas
        await _client
            .from('session_logs')
            .delete()
            .inFilter('id', ids);
      }

      if (mounted) {
        mostrarToast(context, '$cantidad sesiones cerradas eliminadas', tipo: TipoToast.exito);
      }
      _cargarSesiones();
      _cargarActividad();
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error al borrar: $e', tipo: TipoToast.error);
      }
    }
  }

  Future<void> _cerrarSesionIndividual(String sessionId) async {
    try {
      await _client.from('session_logs').update({
        'is_active': false,
        'logout_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);

      if (mounted) {
        mostrarToast(context, 'Sesión cerrada', tipo: TipoToast.exito);
      }
      _cargarSesiones();
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
      }
    }
  }

  Future<void> _cerrarTodasLasSesiones() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar todas las sesiones'),
        content: const Text(
            '¿Estás seguro? Esto cerrará todas las sesiones activas de todos los usuarios.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar todas'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _client.from('session_logs').update({
        'is_active': false,
        'logout_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('is_active', true);

      if (mounted) {
        mostrarToast(context, 'Todas las sesiones han sido cerradas', tipo: TipoToast.exito);
      }
      _cargarSesiones();
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
      }
    }
  }

  Future<void> _cargarSesiones() async {
    setState(() => _cargandoSesiones = true);
    try {
      final datos = await _client
          .from('session_logs')
          .select('''
        id, platform, device, is_active,
        login_at, last_active_at, logout_at,
        profiles(id, full_name, role, avatar_url)
      ''')
          .order('login_at', ascending: false)
          .range(0, _tamanoPagina - 1);
      final pagina = List<Map<String, dynamic>>.from(datos);
      setState(() {
        _sesiones = pagina;
        _haySesionesRestantes = pagina.length == _tamanoPagina;
      });
    } catch (_) {} finally {
      setState(() => _cargandoSesiones = false);
    }
  }

  Future<void> _cargarMasSesiones() async {
    if (_cargandoMasSesiones || !_haySesionesRestantes) return;
    setState(() => _cargandoMasSesiones = true);
    try {
      final desde = _sesiones.length;
      final datos = await _client
          .from('session_logs')
          .select('''
        id, platform, device, is_active,
        login_at, last_active_at, logout_at,
        profiles(id, full_name, role, avatar_url)
      ''')
          .order('login_at', ascending: false)
          .range(desde, desde + _tamanoPagina - 1);
      final pagina = List<Map<String, dynamic>>.from(datos);
      setState(() {
        _sesiones = [..._sesiones, ...pagina];
        _haySesionesRestantes = pagina.length == _tamanoPagina;
      });
    } catch (_) {} finally {
      setState(() => _cargandoMasSesiones = false);
    }
  }

  Future<void> _cargarActividad() async {
    setState(() => _cargandoActividad = true);
    try {
      final datos = await _client
          .from('activity_logs')
          .select('''
        id, event_type, event_name, created_at, extra,
        profiles(id, full_name, role),
        session_logs(platform, device)
      ''')
          .order('created_at', ascending: false)
          .range(0, _tamanoPagina - 1);
      final pagina = List<Map<String, dynamic>>.from(datos);
      setState(() {
        _actividad = pagina;
        _hayActividadRestante = pagina.length == _tamanoPagina;
      });
    } catch (_) {} finally {
      setState(() => _cargandoActividad = false);
    }
  }

  Future<void> _cargarMasActividad() async {
    if (_cargandoMasActividad || !_hayActividadRestante) return;
    setState(() => _cargandoMasActividad = true);
    try {
      final desde = _actividad.length;
      final datos = await _client
          .from('activity_logs')
          .select('''
        id, event_type, event_name, created_at, extra,
        profiles(id, full_name, role),
        session_logs(platform, device)
      ''')
          .order('created_at', ascending: false)
          .range(desde, desde + _tamanoPagina - 1);
      final pagina = List<Map<String, dynamic>>.from(datos);
      setState(() {
        _actividad = [..._actividad, ...pagina];
        _hayActividadRestante = pagina.length == _tamanoPagina;
      });
    } catch (_) {} finally {
      setState(() => _cargandoMasActividad = false);
    }
  }

  List<Map<String, dynamic>> get _sesionesFiltradas {
    switch (_filtroSesion) {
      case 'activas':
        return _sesiones.where((s) => s['is_active'] == true).toList();
      case 'cerradas':
        return _sesiones.where((s) => s['is_active'] == false).toList();
      default:
        return _sesiones;
    }
  }

  List<Map<String, dynamic>> get _actividadFiltrada {
    if (_filtroEvento == 'todos') return _actividad;
    return _actividad.where((a) => a['event_type'] == _filtroEvento).toList();
  }

  // Estadísticas rápidas
  int get _totalActivas => _sesiones.where((s) => s['is_active'] == true).length;
  int get _totalCerradas => _sesiones.where((s) => s['is_active'] == false).length;
  Set<String> get _usuariosUnicos {
    final ids = <String>{};
    for (final s in _sesiones) {
      final p = s['profiles'] as Map?;
      if (p != null) ids.add(p['id'] as String? ?? '');
    }
    ids.remove('');
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Logs del sistema'),
        actions: [
          IconButton(
            onPressed: _borrarSesionesCerradas,
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            tooltip: 'Borrar sesiones cerradas',
          ),
          IconButton(
            onPressed: _cerrarTodasLasSesiones,
            icon: const Icon(Icons.power_settings_new, color: Colors.red),
            tooltip: 'Cerrar todas las sesiones',
          ),
          IconButton(
            onPressed: () { _cargarSesiones(); _cargarActividad(); },
            icon: const Icon(Icons.refresh_outlined, color: kTextSub),
          ),
        ],
      ),
      body: EnvolturaResponsiva(
        child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // ── Tabs ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10)),
                labelColor: Colors.white,
                unselectedLabelColor: kTextSub,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Sesiones (${_sesiones.length})'),
                  Tab(text: 'Actividad (${_actividad.length})'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // ── TAB SESIONES ──────────────────────────
                  _cargandoSesiones
                      ? const Center(child: CircularProgressIndicator())
                      : Column(children: [
                          // Resumen estadísticas
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Row(children: [
                              _StatCard(
                                label: 'Activas',
                                valor: '$_totalActivas',
                                color: Colors.green,
                                icono: Icons.circle,
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                label: 'Cerradas',
                                valor: '$_totalCerradas',
                                color: Colors.grey,
                                icono: Icons.circle_outlined,
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                label: 'Usuarios',
                                valor: '${_usuariosUnicos.length}',
                                color: color,
                                icono: Icons.people_outline,
                              ),
                            ]),
                          ),
                          // Filtros
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(children: [
                              _ChipFiltro('todas', 'Todas', _filtroSesion, color,
                                  () => setState(() => _filtroSesion = 'todas')),
                              _ChipFiltro('activas', '● Activas', _filtroSesion,
                                  Colors.green,
                                  () => setState(() => _filtroSesion = 'activas')),
                              _ChipFiltro('cerradas', '○ Cerradas', _filtroSesion,
                                  Colors.grey,
                                  () => setState(() => _filtroSesion = 'cerradas')),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _sesionesFiltradas.isEmpty
                                ? const Center(child: Text('Sin sesiones',
                                    style: TextStyle(color: kTextSub)))
                                : RefreshIndicator(
                                    onRefresh: _cargarSesiones,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 4, 20, 100),
                                      itemCount: _sesionesFiltradas.length +
                                          (_haySesionesRestantes ? 1 : 0),
                                      itemBuilder: (_, i) {
                                        if (i >= _sesionesFiltradas.length) {
                                          return BotonCargarMas(
                                            cargando: _cargandoMasSesiones,
                                            onTap: _cargarMasSesiones,
                                          );
                                        }
                                        return EntradaAnimada(
                                            index: i,
                                            child: _TarjetaSesion(
                                                sesion: _sesionesFiltradas[i],
                                                color: color,
                                                onCerrar: _cerrarSesionIndividual));
                                      },
                                    ),
                                  ),
                          ),
                        ]),

                  // ── TAB ACTIVIDAD ─────────────────────────
                  Column(children: [
                    // Filtros de evento
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        _ChipFiltro('todos', 'Todos', _filtroEvento, color,
                            () => setState(() => _filtroEvento = 'todos')),
                        _ChipFiltro('screen_view', '📱 Pantallas', _filtroEvento,
                            Colors.blue,
                            () => setState(() => _filtroEvento = 'screen_view')),
                        _ChipFiltro('tap', '👆 Taps', _filtroEvento,
                            Colors.orange,
                            () => setState(() => _filtroEvento = 'tap')),
                        _ChipFiltro('feature', '⭐ Features', _filtroEvento,
                            color,
                            () => setState(() => _filtroEvento = 'feature')),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    // Contador
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(children: [
                        Text('${_actividadFiltrada.length} eventos',
                            style:
                                const TextStyle(color: kTextSub, fontSize: 12)),
                      ]),
                    ),
                    Expanded(
                      child: _cargandoActividad
                          ? const Center(child: CircularProgressIndicator())
                          : _actividadFiltrada.isEmpty
                              ? const Center(child: Text('Sin actividad',
                                  style: TextStyle(color: kTextSub)))
                              : RefreshIndicator(
                                  onRefresh: _cargarActividad,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 4, 20, 100),
                                    itemCount: _actividadFiltrada.length +
                                        (_hayActividadRestante ? 1 : 0),
                                    itemBuilder: (_, i) {
                                      if (i >= _actividadFiltrada.length) {
                                        return BotonCargarMas(
                                          cargando: _cargandoMasActividad,
                                          onTap: _cargarMasActividad,
                                        );
                                      }
                                      return EntradaAnimada(
                                          index: i,
                                          child: _FilaActividad(
                                              evento: _actividadFiltrada[i],
                                              color: color));
                                    },
                                  ),
                                ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final IconData icono;
  const _StatCard(
      {required this.label,
      required this.valor,
      required this.color,
      required this.icono});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: kTextSub)),
          ]),
        ]),
      ),
    );
  }
}

// ── Tarjeta de sesión detallada ────────────────────────────
class _TarjetaSesion extends StatelessWidget {
  final Map<String, dynamic> sesion;
  final Color color;
  final void Function(String sessionId)? onCerrar;
  const _TarjetaSesion({required this.sesion, required this.color, this.onCerrar});

  @override
  Widget build(BuildContext context) {
    final perfil = sesion['profiles'] as Map<String, dynamic>?;
    final nombre = perfil?['full_name'] as String? ?? 'Desconocido';
    final rol = perfil?['role'] as String? ?? 'client';
    final activa = sesion['is_active'] as bool? ?? false;
    final plataforma = sesion['platform'] as String? ?? 'desconocido';
    final dispositivo = sesion['device'] as String? ?? '';
    final loginAt = sesion['login_at'] as String?;
    final lastActive = sesion['last_active_at'] as String?;
    final logoutAt = sesion['logout_at'] as String?;

    final duracion = _calcularDuracion(loginAt, logoutAt, lastActive, activa);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: activa
              ? Colors.green.withOpacity(0.4)
              : const Color(0xFFE5E5EA),
          width: activa ? 1.5 : 1,
        ),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
      ),
      child: Column(children: [
        // Cabecera
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            // Avatar inicial
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: activa
                    ? Colors.green.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: activa ? Colors.green : Colors.grey,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                        fontSize: 14)),
                Row(children: [
                  _BadgeMini(_rolLabel(rol), _rolColor(rol)),
                  const SizedBox(width: 6),
                  Icon(
                      plataforma == 'android'
                          ? Icons.android
                          : plataforma == 'ios'
                              ? Icons.phone_iphone
                              : Icons.computer,
                      size: 13,
                      color: kTextSub),
                  const SizedBox(width: 2),
                  Text(plataforma,
                      style:
                          const TextStyle(color: kTextSub, fontSize: 11)),
                ]),
              ]),
            ),
            // Badge estado + botón cerrar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activa
                        ? Colors.green.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activa ? '● ACTIVA' : '○ CERRADA',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: activa ? Colors.green : Colors.grey,
                        letterSpacing: 0.5),
                  ),
                ),
                if (activa && onCerrar != null)
                  GestureDetector(
                    onTap: () => onCerrar!(sesion['id'] as String),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.power_settings_new,
                                size: 11, color: Colors.red),
                            SizedBox(width: 3),
                            Text('Cerrar',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ]),
        ),

        // Línea divisoria
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Divider(height: 1, color: Color(0xFFF2F2F7)),
        ),

        // Detalles del dispositivo
        if (dispositivo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(children: [
              const Icon(Icons.devices_outlined, size: 13, color: kTextSub),
              const SizedBox(width: 4),
              Expanded(
                child: Text(dispositivo,
                    style: const TextStyle(color: kTextSub, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),

        // Tiempos
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Column(children: [
            if (loginAt != null)
              _FilaTiempo(Icons.login, 'Inicio de sesión', loginAt,
                  color: Colors.blue),
            if (lastActive != null && activa)
              _FilaTiempo(Icons.access_time_rounded,
                  'Última actividad', lastActive,
                  color: Colors.orange),
            if (logoutAt != null)
              _FilaTiempo(Icons.logout, 'Cierre de sesión', logoutAt,
                  color: Colors.red),
            if (duracion != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, size: 13, color: kTextSub),
                  const SizedBox(width: 4),
                  Text('Duración: $duracion',
                      style: const TextStyle(
                          color: kTextSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }

  String? _calcularDuracion(String? loginAt, String? logoutAt,
      String? lastActive, bool activa) {
    final inicio = loginAt != null ? DateTime.tryParse(loginAt) : null;
    if (inicio == null) return null;

    final fin = activa
        ? DateTime.now()
        : (logoutAt != null
            ? DateTime.tryParse(logoutAt)
            : (lastActive != null ? DateTime.tryParse(lastActive) : null));
    if (fin == null) return null;

    final diff = fin.difference(inicio);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  String _rolLabel(String rol) => switch (rol) {
        'sysadmin' => 'SYSADMIN',
        'super_admin' => 'SUPER ADMIN',
        'admin' => 'ADMIN',
        'employee' => 'EMPLEADO',
        _ => 'CLIENTE',
      };

  Color _rolColor(String rol) => switch (rol) {
        'sysadmin' => Colors.deepPurple,
        'super_admin' || 'admin' => Colors.orange,
        'employee' => Colors.blue,
        _ => Colors.grey,
      };
}

class _FilaTiempo extends StatelessWidget {
  final IconData icono;
  final String label;
  final String iso;
  final Color color;

  const _FilaTiempo(this.icono, this.label, this.iso, {required this.color});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    final texto = dt == null
        ? iso
        : '${_dia(dt)} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(icono, size: 13, color: color),
        const SizedBox(width: 5),
        Text('$label: ',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(texto,
              style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 11)),
        ),
      ]),
    );
  }

  String _dia(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _BadgeMini extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeMini(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Chip de filtro ─────────────────────────────────────────
Widget _ChipFiltro(String valor, String label, String actual, Color color,
    VoidCallback onTap) {
  final activo = valor == actual;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: activo ? color : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
        border: activo ? null : Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Text(label,
          style: TextStyle(
              color: activo ? Colors.white : kTextSub,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Fila de actividad detallada ────────────────────────────
class _FilaActividad extends StatelessWidget {
  final Map<String, dynamic> evento;
  final Color color;
  const _FilaActividad({required this.evento, required this.color});

  @override
  Widget build(BuildContext context) {
    final perfil = evento['profiles'] as Map<String, dynamic>?;
    final sesionLog = evento['session_logs'] as Map<String, dynamic>?;
    final nombre = perfil?['full_name'] as String? ?? 'Desconocido';
    final rol = perfil?['role'] as String? ?? '';
    final tipo = evento['event_type'] as String? ?? '';
    final eventoNombre = evento['event_name'] as String? ?? '';
    final fecha = evento['created_at'] as String?;
    final extra = evento['extra'] as Map<String, dynamic>?;
    final plataforma = sesionLog?['platform'] as String? ?? '';
    final dispositivo = sesionLog?['device'] as String? ?? '';

    final (icono, iconColor, tipoLabel) = switch (tipo) {
      'screen_view' => (Icons.phone_android_outlined, Colors.blue, 'PANTALLA'),
      'tap' => (Icons.touch_app_outlined, Colors.orange, 'TAP'),
      'feature' => (Icons.star_outline_rounded, color, 'FEATURE'),
      _ => (Icons.circle_outlined, Colors.grey, tipo.toUpperCase()),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Icono tipo
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Nombre del evento
            Text(eventoNombre,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                    fontSize: 13)),
            const SizedBox(height: 2),
            // Usuario y rol
            Row(children: [
              Text(nombre,
                  style: const TextStyle(color: kTextSub, fontSize: 11)),
              if (rol.isNotEmpty) ...[
                const Text(' · ',
                    style: TextStyle(color: kTextSub, fontSize: 11)),
                Text(rol,
                    style: const TextStyle(
                        color: kTextSub,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ]),
            // Dispositivo/plataforma si hay sesión
            if (plataforma.isNotEmpty || dispositivo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                [
                  if (plataforma.isNotEmpty) plataforma,
                  if (dispositivo.isNotEmpty)
                    dispositivo.length > 40
                        ? '${dispositivo.substring(0, 40)}…'
                        : dispositivo,
                ].join(' · '),
                style: const TextStyle(color: kTextSub, fontSize: 10),
              ),
            ],
            // Extra data
            if (extra != null && extra.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  extra.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(' · '),
                  style:
                      const TextStyle(color: kTextSub, fontSize: 10),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        // Badge tipo + hora
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tipoLabel,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    letterSpacing: 0.3)),
          ),
          if (fecha != null) ...[
            const SizedBox(height: 3),
            Text(_fmtFecha(fecha),
                style:
                    const TextStyle(color: kTextSub, fontSize: 10)),
            Text(_fmtHora(fecha),
                style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ]),
      ]),
    );
  }

  String _fmtFecha(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _fmtHora(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
