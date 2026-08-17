import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../data/loyalty_repository.dart';
import '../../domain/models/loyalty.dart';

class PaginaConfigLealtad extends StatefulWidget {
  const PaginaConfigLealtad({super.key});

  @override
  State<PaginaConfigLealtad> createState() => _PaginaConfigLealtadState();
}

class _PaginaConfigLealtadState extends State<PaginaConfigLealtad> {
  final _repo = RepositorioLealtad();
  bool _cargando = true;
  bool _guardando = false;

  bool _activo = true;
  bool _ganaPorReservas = true;
  bool _ganaPorPedidos = true;
  final _ctrlNombre = TextEditingController();
  final _ctrlMontoPorPunto = TextEditingController();
  final _ctrlPuntosPorPesoCanje = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlMontoPorPunto.dispose();
    _ctrlPuntosPorPesoCanje.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final config = await _repo.obtenerConfig();
    if (!mounted) return;
    setState(() {
      _activo = config.activo;
      _ganaPorReservas = config.ganaPorReservas;
      _ganaPorPedidos = config.ganaPorPedidos;
      _ctrlNombre.text = config.nombrePrograma;
      _ctrlMontoPorPunto.text = config.montoPorPunto.toStringAsFixed(0);
      _ctrlPuntosPorPesoCanje.text = config.puntosPorPesoCanje.toStringAsFixed(0);
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_ctrlMontoPorPunto.text);
    final canje = double.tryParse(_ctrlPuntosPorPesoCanje.text);
    if (monto == null || monto <= 0 || canje == null || canje <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa que los números sean válidos y mayores a 0')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await _repo.actualizarConfig(ConfigLealtad(
        activo: _activo,
        nombrePrograma: _ctrlNombre.text.trim().isEmpty
            ? 'Programa de lealtad'
            : _ctrlNombre.text.trim(),
        montoPorPunto: monto,
        puntosPorPesoCanje: canje,
        ganaPorReservas: _ganaPorReservas,
        ganaPorPedidos: _ganaPorPedidos,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuración guardada'),
            backgroundColor: context.colorPrimario,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    final monto = double.tryParse(_ctrlMontoPorPunto.text) ?? 0;
    final canje = double.tryParse(_ctrlPuntosPorPesoCanje.text) ?? 0;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Programa de lealtad')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vista previa de la regla
                  if (monto > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cada \$${monto.toStringAsFixed(0)} gastados = 1 punto'
                              '${canje > 0 ? ' · $canje puntos = \$1 al canjear' : ''}',
                              style: TextStyle(
                                  color: color, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  _TarjetaSwitch(
                    titulo: 'Programa activo',
                    subtitulo: 'Si está apagado, nadie gana ni ve puntos',
                    valor: _activo,
                    onCambio: (v) => setState(() => _activo = v),
                  ),
                  const SizedBox(height: 20),

                  const Text('Nombre del programa',
                      style: TextStyle(
                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  _campoTexto(_ctrlNombre, hint: 'Programa de lealtad'),
                  const SizedBox(height: 24),

                  const Text('Cómo se ganan los puntos',
                      style: TextStyle(
                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  _TarjetaSwitch(
                    titulo: 'Reservas completadas',
                    subtitulo: 'Servicios/citas del salón',
                    valor: _ganaPorReservas,
                    onCambio: (v) => setState(() => _ganaPorReservas = v),
                    compacta: true,
                  ),
                  const SizedBox(height: 10),
                  _TarjetaSwitch(
                    titulo: 'Pedidos pagados',
                    subtitulo: 'Compras de productos',
                    valor: _ganaPorPedidos,
                    onCambio: (v) => setState(() => _ganaPorPedidos = v),
                    compacta: true,
                  ),
                  const SizedBox(height: 24),

                  const Text('Pesos gastados por cada punto',
                      style: TextStyle(
                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Ej. 100 → gastar \$100 da 1 punto',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                  const SizedBox(height: 10),
                  _campoNumero(_ctrlMontoPorPunto, prefijo: '\$ '),
                  const SizedBox(height: 24),

                  const Text('Puntos necesarios para canjear \$1',
                      style: TextStyle(
                          color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Ej. 10 → 10 puntos equivalen a \$1 de descuento',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                  const SizedBox(height: 10),
                  _campoNumero(_ctrlPuntosPorPesoCanje),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _campoTexto(TextEditingController ctrl, {required String hint}) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _campoNumero(TextEditingController ctrl, {String? prefijo}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      decoration: InputDecoration(
        prefixText: prefijo,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _TarjetaSwitch extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool valor;
  final ValueChanged<bool> onCambio;
  final bool compacta;

  const _TarjetaSwitch({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onCambio,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compacta ? 8 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitulo, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: onCambio,
            activeThumbColor: context.colorPrimario,
          ),
        ],
      ),
    );
  }
}
