import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/entrada_animada.dart';
import '../common/app_widgets.dart';
import '../common/skeleton.dart';
import 'scan_qr_page.dart';

class PaginaReservasEmpleado extends StatefulWidget {
  const PaginaReservasEmpleado({super.key});

  @override
  State<PaginaReservasEmpleado> createState() => _PaginaReservasEmpleadoState();
}

class _PaginaReservasEmpleadoState extends State<PaginaReservasEmpleado> {
  EstadoReserva? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<ProveedorAuth>().perfil?.id;
      if (id != null) context.read<ProveedorReserva>().cargarReservasEmpleado(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorReserva>();

    final filtradas = (_filtro == null
        ? proveedor.reservas.toList()
        : proveedor.reservas.where((b) => b.estado == _filtro).toList())
      ..sort((a, b) => b.fechaReserva.compareTo(a.fechaReserva));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded, color: context.colorPrimario),
            tooltip: 'Escanear QR',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaginaEscanearQR()),
            ),
          ),
        ],
      ),
      body: EnvolturaResponsiva(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _ChipFiltro(label: 'Todas', selected: _filtro == null, onTap: () => setState(() => _filtro = null)),
                const SizedBox(width: 8),
                ...EstadoReserva.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ChipFiltro(
                        label: s.label,
                        selected: _filtro == s,
                        onTap: () => setState(() => _filtro = s),
                      ),
                    )),
              ],
            ),
          ),

          Expanded(
            child: proveedor.cargandoReservas
                ? const ListaEsqueleto()
                : filtradas.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.calendar_today_outlined,
                        titulo: 'Sin reservas',
                      )
                    : _ListaConSeparadores(reservas: filtradas),
          ),
        ],
      ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipFiltro({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? context.colorPrimario : kCard,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: kDivider, width: 0.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: context.colorPrimario.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ]
              : kNeumorphicShadowsSmall,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : kTextSub,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ListaConSeparadores extends StatelessWidget {
  final List<Reserva> reservas;
  const _ListaConSeparadores({required this.reservas});

  String _etiquetaDia(DateTime fecha) {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    if (_mismoDia(fecha, hoy)) return 'Hoy';
    if (_mismoDia(fecha, ayer)) return 'Ayer';
    return DateFormat('dd MMM yyyy', 'es_ES').format(fecha);
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final items = <dynamic>[];
    String? lastLabel;
    for (final r in reservas) {
      final label = _etiquetaDia(r.fechaReserva);
      if (label != lastLabel) {
        items.add(label);
        lastLabel = label;
      }
      items.add(r);
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          if (item is String) return _SeparadorDia(etiqueta: item);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EntradaAnimada(
              index: entry.key,
              child: _TarjetaReservaEmpleado(
                  key: ValueKey((item as Reserva).id), reserva: item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SeparadorDia extends StatelessWidget {
  final String etiqueta;
  const _SeparadorDia({required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: const Color(0xFFD1D1D6), thickness: 0.8)),
          const SizedBox(width: 10),
          Text(etiqueta,
              style: const TextStyle(
                  color: Color(0xFF6E6E73),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: const Color(0xFFD1D1D6), thickness: 0.8)),
        ],
      ),
    );
  }
}

class _TarjetaReservaEmpleado extends StatefulWidget {
  final Reserva reserva;
  const _TarjetaReservaEmpleado({super.key, required this.reserva});

  @override
  State<_TarjetaReservaEmpleado> createState() => _TarjetaReservaEmpleadoState();
}

class _TarjetaReservaEmpleadoState extends State<_TarjetaReservaEmpleado> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final fechaTexto = DateFormat('dd MMM yyyy', 'es_ES').format(r.fechaReserva);
    final inicial = (r.nombreCliente ?? '?')[0].toUpperCase();

    return GestureDetector(
      onTap: () => setState(() => _expandida = !_expandida),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            // Fila principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.nombreServicio ?? 'Servicio'} — ${(r.nombreCliente ?? '—').split(' ').first}',
                          style: const TextStyle(
                              color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(fechaTexto,
                            style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 12)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: context.colorPrimario.withOpacity(0.15),
                    child: Text(inicial,
                        style: TextStyle(
                            color: context.colorPrimario,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  ChipEstado(etiqueta: r.estado.label, color: r.estado.color),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expandida ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF6E6E73), size: 20),
                  ),
                ],
              ),
            ),
            // Detalle expandible
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expandida ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E5EA))),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilaDetalle(Icons.person_outline, 'Cliente: ${r.nombreCliente ?? '—'}'),
                    const SizedBox(height: 6),
                    _FilaDetalle(Icons.access_time_outlined, '${r.horaInicio} – ${r.horaFin}'),
                    if (r.estado == EstadoReserva.confirmed) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF34C759)),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text('Escanea el QR del cliente para marcarla como pagada',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF34C759), fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _FilaDetalle(this.icono, this.texto);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 14, color: const Color(0xFF6E6E73)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(texto,
              style: const TextStyle(color: Color(0xFF3C3C43), fontSize: 12)),
        ),
      ],
    );
  }
}
