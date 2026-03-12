import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_theme.dart';

class PaginaCarrito extends StatelessWidget {
  const PaginaCarrito({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<ProveedorCarrito>();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          if (!carrito.vacio)
            TextButton(
              onPressed: () => carrito.limpiar(),
              child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: carrito.vacio
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shopping_cart_outlined,
                        size: 48, color: kTextMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('Carrito vacío',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 6),
                  const Text('Agrega productos desde la Tienda',
                      style: TextStyle(color: kTextMuted, fontSize: 13)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: carrito.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = carrito.items[i];
                      final precio = item.producto.precio % 1 == 0
                          ? '\$${item.producto.precio.toInt()}'
                          : '\$${item.producto.precio.toStringAsFixed(2)}';
                      final subtotal = item.subtotal % 1 == 0
                          ? '\$${item.subtotal.toInt()}'
                          : '\$${item.subtotal.toStringAsFixed(2)}';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: item.producto.urlImagen != null
                                  ? Image.network(
                                      item.producto.urlImagen!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _imgPlaceholder(),
                                    )
                                  : _imgPlaceholder(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.producto.nombre,
                                      style: const TextStyle(
                                          color: Color(0xFF1C1C1E),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(precio,
                                      style: const TextStyle(
                                          color: Color(0xFF6E6E73), fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                _BtnCantidad(
                                  icono: Icons.remove,
                                  onTap: () =>
                                      carrito.decrementar(item.producto.id),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text('${item.cantidad}',
                                      style: const TextStyle(
                                          color: Color(0xFF1C1C1E),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ),
                                _BtnCantidad(
                                  icono: Icons.add,
                                  onTap: () => carrito.agregar(item.producto),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Text(subtotal,
                                style: TextStyle(
                                    color: context.colorPrimario,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _ResumenPedido(carrito: carrito),
              ],
            ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 64,
        height: 64,
        color: const Color(0xFFF2F2F7),
        child: const Icon(Icons.inventory_2_outlined,
            color: kTextMuted, size: 24),
      );
}

class _BtnCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _BtnCantidad({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: context.colorPrimario, width: 1.5),
        ),
        child: Icon(icono, size: 14, color: context.colorPrimario),
      ),
    );
  }
}

class _ResumenPedido extends StatefulWidget {
  final ProveedorCarrito carrito;
  const _ResumenPedido({required this.carrito});

  @override
  State<_ResumenPedido> createState() => _ResumenPedidoState();
}

class _ResumenPedidoState extends State<_ResumenPedido> {
  bool _procesando = false;

  String _fmtPrecio(double v) =>
      v % 1 == 0 ? '\$${v.toInt()}' : '\$${v.toStringAsFixed(2)}';

  Future<void> _confirmar() async {
    final perfil = context.read<ProveedorAuth>().perfil;
    if (perfil == null) {
      context.go('/login');
      return;
    }
    setState(() => _procesando = true);

    final exito = await context.read<ProveedorPedido>().realizarPedido(
          clienteId: perfil.id,
          items: widget.carrito.items,
        );

    if (!mounted) return;
    setState(() => _procesando = false);

    if (exito) {
      widget.carrito.limpiar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido realizado con éxito!'),
          backgroundColor: Color(0xFF4ECDC4),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.read<ProveedorPedido>().error ??
                'Error al realizar pedido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.carrito.totalItems} productos',
                  style: const TextStyle(color: Color(0xFF6E6E73), fontSize: 14)),
              Text(_fmtPrecio(widget.carrito.total),
                  style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _procesando ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorPrimario,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _procesando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Confirmar pedido',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
