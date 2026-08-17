import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/loyalty_repository.dart';
import '../../domain/models/loyalty.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/entrada_animada.dart';
import '../common/app_widgets.dart';

class PaginaLealtad extends StatefulWidget {
  const PaginaLealtad({super.key});

  @override
  State<PaginaLealtad> createState() => _PaginaLealtadState();
}

class _PaginaLealtadState extends State<PaginaLealtad> {
  final _repo = RepositorioLealtad();
  bool _cargando = true;
  ConfigLealtad? _config;
  List<MovimientoLealtad> _movimientos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final idPerfil = context.read<ProveedorAuth>().perfil?.id;
    if (idPerfil == null) return;
    final config = await _repo.obtenerConfig();
    final movimientos = await _repo.obtenerMovimientos(idPerfil);
    if (!mounted) return;
    setState(() {
      _config = config;
      _movimientos = movimientos;
      _cargando = false;
    });
  }

  double get _saldo => _movimientos.fold<double>(0, (t, m) => t + m.puntos);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programa de lealtad')),
      body: EnvolturaResponsiva(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : !( _config?.activo ?? false)
                ? const EstadoVacio(
                    icono: Icons.card_giftcard_outlined,
                    titulo: 'Programa no disponible',
                    subtitulo: 'El programa de lealtad no está activo por el momento',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      _TarjetaSaldo(config: _config!, saldo: _saldo),
                      const SizedBox(height: 20),
                      const Text('Historial',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 12),
                      if (_movimientos.isEmpty)
                        const EstadoVacio(
                          icono: Icons.history,
                          titulo: 'Sin movimientos todavía',
                          subtitulo: 'Tus reservas completadas y pedidos pagados suman puntos aquí',
                        )
                      else
                        ...List.generate(_movimientos.length, (i) {
                          return EntradaAnimada(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FilaMovimiento(movimiento: _movimientos[i]),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}

class _TarjetaSaldo extends StatelessWidget {
  final ConfigLealtad config;
  final double saldo;
  const _TarjetaSaldo({required this.config, required this.saldo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorPrimario,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(config.nombrePrograma,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('${saldo.toStringAsFixed(0)} pts',
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Equivalen a \$${config.valorEnPesos(saldo).toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Divider(color: Colors.white24, height: 24),
          Text(
            'Ganas 1 punto por cada \$${config.montoPorPunto.toStringAsFixed(0)} gastados',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  final MovimientoLealtad movimiento;
  const _FilaMovimiento({required this.movimiento});

  String get _etiquetaOrigen {
    switch (movimiento.origen) {
      case 'reserva':
        return 'Reserva completada';
      case 'pedido':
        return 'Pedido pagado';
      default:
        return 'Ajuste';
    }
  }

  IconData get _icono {
    switch (movimiento.origen) {
      case 'reserva':
        return Icons.event_available_outlined;
      case 'pedido':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.tune;
    }
  }

  @override
  Widget build(BuildContext context) {
    final positivo = movimiento.puntos >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorPrimario.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icono, color: context.colorPrimario, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movimiento.descripcion ?? _etiquetaOrigen,
                    style: const TextStyle(
                        color: Color(0xFF1C1C1E), fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(DateFormat('dd MMM yyyy', 'es_ES').format(movimiento.creadoEl),
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${positivo ? '+' : ''}${movimiento.puntos.toStringAsFixed(0)} pts',
            style: TextStyle(
              color: positivo ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
