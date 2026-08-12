import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import '../../data/activity_service.dart';
import '../client/profile_page.dart';
import '../common/app_widgets.dart';

class PaginaTableroSysadmin extends StatefulWidget {
  const PaginaTableroSysadmin({super.key});

  @override
  State<PaginaTableroSysadmin> createState() => _PaginaTableroSysadminState();
}

class _PaginaTableroSysadminState extends State<PaginaTableroSysadmin> {
  final _client = Supabase.instance.client;
  bool _cargando = true;
  int _totalUsuarios = 0;
  int _sesionesActivas = 0;
  int _totalPedidos = 0;
  double _ingresosTotales = 0;
  List<Map<String, dynamic>> _ultimasSesiones = [];

  @override
  void initState() {
    super.initState();
    _cargar();
    ServicioActividad.instancia.registrarPantalla('SysAdmin_Dashboard');
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final usuarios = await _client.from('profiles').select('id');
      final sesiones = await _client.from('session_logs')
          .select('id').eq('is_active', true);
      final pedidos = await _client.from('orders')
          .select('total').neq('status', 'cancelled');
      final statsEmpleados = await _client.from('employee_stats').select('ingresos_totales');
      final ultimas = await _client.from('session_logs').select('''
          id, platform, device, is_active, login_at, last_active_at,
          profiles(full_name, role)
        ''').order('login_at', ascending: false).limit(10);

      final listaPedidos = List<Map<String, dynamic>>.from(pedidos);
      final ingresosTienda = listaPedidos.fold<double>(
          0, (acc, p) => acc + ((p['total'] as num?)?.toDouble() ?? 0));
      final ingresosServicios = (statsEmpleados as List).fold<double>(
          0, (acc, e) => acc + (((e as Map)['ingresos_totales'] as num?)?.toDouble() ?? 0));
      final ingresos = ingresosServicios + ingresosTienda;

      setState(() {
        _totalUsuarios = (usuarios as List).length;
        _sesionesActivas = (sesiones as List).length;
        _totalPedidos = listaPedidos.length;
        _ingresosTotales = ingresos;
        _ultimasSesiones = List<Map<String, dynamic>>.from(ultimas);
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    final tiendaHabilitada = context.watch<ProveedorConfig>().tiendaHabilitada;
    final color = context.colorPrimario;
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargar,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [const Color(0xFF1C1C1E), color.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const CircleAvatar(
                                radius: 21,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(kUrlLogoBarberia),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const PaginaPerfil()),
                                ),
                                child: CircleAvatar(
                                  radius: 21,
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  backgroundImage: perfil?.urlAvatar != null
                                      ? NetworkImage(perfil!.urlAvatar!)
                                      : null,
                                  child: perfil?.urlAvatar == null
                                      ? const Icon(Icons.shield_outlined,
                                          color: Colors.white, size: 20)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SYSADMIN',
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 11, letterSpacing: 1.5)),
                                    Text(perfil?.nombreCompleto ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const IconoNotificaciones(color: Colors.white),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: _cargar,
                                icon: const Icon(Icons.refresh, color: Colors.white70),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Text(fmt.format(_ingresosTotales),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold)),
                            const Text('Ingresos totales del sistema',
                                style: TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),

                      // Stats grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _Stat(icono: Icons.people_outline, label: 'Usuarios',
                              valor: '$_totalUsuarios', color: color),
                          _Stat(icono: Icons.wifi_rounded, label: 'Sesiones activas',
                              valor: '$_sesionesActivas', color: Colors.green),
                          if (tiendaHabilitada)
                            _Stat(icono: Icons.receipt_long_outlined, label: 'Pedidos',
                                valor: '$_totalPedidos', color: Colors.orange),
                          _Stat(icono: Icons.trending_up_rounded, label: 'Ingresos',
                              valor: fmt.format(_ingresosTotales), color: Colors.teal),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Últimas sesiones
                      const Text('Actividad reciente',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 12),
                      ..._ultimasSesiones.map((s) => _FilaSesion(sesion: s)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final Color color;
  const _Stat({required this.icono, required this.label,
      required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icono, color: color, size: 18),
        ),
        const Spacer(),
        Text(valor, style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
        Text(label, style: const TextStyle(color: kTextSub, fontSize: 11)),
      ]),
    );
  }
}

class _FilaSesion extends StatelessWidget {
  final Map<String, dynamic> sesion;
  const _FilaSesion({required this.sesion});

  @override
  Widget build(BuildContext context) {
    final perfil = sesion['profiles'] as Map<String, dynamic>?;
    final nombre = perfil?['full_name'] as String? ?? 'Usuario';
    final activa = sesion['is_active'] as bool? ?? false;
    final plataforma = sesion['platform'] as String? ?? '?';
    final lastActive = sesion['last_active_at'] as String?;
    final hace = lastActive != null
        ? _tiempoRelativo(DateTime.parse(lastActive))
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: activa
                ? Colors.green.withOpacity(0.12)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            plataforma == 'android' ? Icons.android : Icons.phone_iphone,
            size: 18,
            color: activa ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E), fontSize: 13)),
            Text('$plataforma · $hace',
                style: const TextStyle(color: kTextSub, fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: activa
                ? Colors.green.withOpacity(0.12)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(activa ? 'Activa' : 'Inactiva',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: activa ? Colors.green : Colors.grey)),
        ),
      ]),
    );
  }

  String _tiempoRelativo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} días';
  }
}
