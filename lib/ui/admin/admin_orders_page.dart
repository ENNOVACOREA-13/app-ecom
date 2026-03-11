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

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pedidos',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFF1C1C1E))),
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined, color: kTextSub),
                    onPressed: () => proveedor.cargarTodosPedidos(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: proveedor.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : proveedor.pedidos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: const BoxDecoration(
                                  color: kCard,
                                  shape: BoxShape.circle,
                                  boxShadow: kNeumorphicShadows,
                                ),
                                child: const Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: kTextMuted),
                              ),
                              const SizedBox(height: 16),
                              const Text('Sin pedidos',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: kText)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: proveedor.pedidos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _TarjetaPedido(pedido: proveedor.pedidos[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  final Pedido pedido;
  const _TarjetaPedido({required this.pedido});

  String _fmtPrecio(double v) =>
      v % 1 == 0 ? '\$${v.toInt()}' : '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final estadoColor = pedido.estado.color;
    final fecha =
        '${pedido.creadoEn.day}/${pedido.creadoEn.month}/${pedido.creadoEn.year} '
        '${pedido.creadoEn.hour.toString().padLeft(2, '0')}:${pedido.creadoEn.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: kNeumorphicShadowsSmall,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.receipt_outlined, color: estadoColor, size: 20),
        ),
        title: Text(
          pedido.nombreCliente ?? 'Cliente',
          style: const TextStyle(
              color: kText, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(fecha,
            style: const TextStyle(color: kTextMuted, fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmtPrecio(pedido.total),
                style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(pedido.estado.etiqueta,
                  style: TextStyle(
                      color: estadoColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        children: [
          // Items
          ...pedido.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: kTextMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.cantidad}x ${item.nombreProducto}',
                        style:
                            const TextStyle(color: kTextSub, fontSize: 13),
                      ),
                    ),
                    Text(
                      _fmtPrecio(item.subtotal),
                      style: const TextStyle(
                          color: kText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          // Status change
          const Text('Cambiar estado:',
              style: TextStyle(color: kTextMuted, fontSize: 12)),
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
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: e.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: e.color.withOpacity(0.4), width: 1),
                        ),
                        child: Text(e.etiqueta,
                            style: TextStyle(
                                color: e.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
