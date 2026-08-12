import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/models/order.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_theme.dart';

class PaginaPedidosAdmin extends StatefulWidget {
  const PaginaPedidosAdmin({super.key});

  @override
  State<PaginaPedidosAdmin> createState() => _PaginaPedidosAdminState();
}

class _PaginaPedidosAdminState extends State<PaginaPedidosAdmin> {
  EstadoPedido? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorPedido>().cargarTodosPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorPedido>();
    final todos = proveedor.pedidos;
    final filtrados = _filtro == null
        ? todos
        : todos.where((p) => p.estado == _filtro).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1C1C1E), size: 22),
            onPressed: () => proveedor.cargarTodosPedidos(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats cards ─────────────────────────────────────
            if (todos.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: EstadoPedido.values.map((e) {
                    final count = todos.where((p) => p.estado == e).length;
                    return _StatChip(estado: e, count: count);
                  }).toList(),
                ),
              ),
            ],

            // ── Filtros ─────────────────────────────────────────
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FiltroChip(
                    label: 'Todos',
                    selected: _filtro == null,
                    onTap: () => setState(() => _filtro = null),
                  ),
                  ...EstadoPedido.values.map((e) => _FiltroChip(
                        label: e.etiqueta,
                        color: e.color,
                        selected: _filtro == e,
                        onTap: () =>
                            setState(() => _filtro = _filtro == e ? null : e),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Lista ────────────────────────────────────────────
            Expanded(
              child: proveedor.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : filtrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 20)
                                  ],
                                ),
                                child: const Icon(Icons.receipt_long_outlined,
                                    size: 48, color: Color(0xFFB0B0B8)),
                              ),
                              const SizedBox(height: 16),
                              const Text('Sin pedidos',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3C3C43))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _TarjetaPedido(pedido: filtrados[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final EstadoPedido estado;
  final int count;
  const _StatChip({required this.estado, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: estado.color)),
          const SizedBox(height: 2),
          Text(estado.etiqueta,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Filtro chip ────────────────────────────────────────────────────────────
class _FiltroChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  const _FiltroChip(
      {required this.label,
      this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colorPrimario;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF3C3C43),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Tarjeta pedido ─────────────────────────────────────────────────────────
class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  const _TarjetaPedido({required this.pedido});

  String _fmtPrecio(double v) =>
      v % 1 == 0 ? '\$${v.toInt()}' : '\$${v.toStringAsFixed(2)}';

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = pedido.estado.color;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: ThemeData.light().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          // ── Barra color izquierda ──
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  pedido.nombreCliente ?? 'Cliente',
                  style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ),
              Text(_fmtPrecio(pedido.total),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 4),
                      Text(_fmtFecha(pedido.creadoEn),
                          style: const TextStyle(
                              color: Color(0xFF8E8E93), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(pedido.estado.etiqueta,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          children: [
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFFF0F0F5),
            ),
            // Items
            ...pedido.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.6),
                            shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Text('${item.cantidad}x ${item.nombreProducto}',
                            style: const TextStyle(
                                color: Color(0xFF3C3C43), fontSize: 13)),
                      ),
                      Text(_fmtPrecio(item.subtotal),
                          style: const TextStyle(
                              color: Color(0xFF1C1C1E),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                )),
            // Total row
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          color: Color(0xFF3C3C43),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(_fmtPrecio(pedido.total),
                      style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
            // Cambiar estado
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Cambiar estado:',
                  style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EstadoPedido.values
                  .where((e) => e != pedido.estado)
                  .map((e) => GestureDetector(
                        onTap: () => context
                            .read<ProveedorPedido>()
                            .actualizarEstado(pedido.id, e.toDbString()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: e.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: e.color.withValues(alpha: 0.35), width: 1),
                          ),
                          child: Text(e.etiqueta,
                              style: TextStyle(
                                  color: e.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
