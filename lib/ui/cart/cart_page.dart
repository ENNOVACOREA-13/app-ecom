import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../data/stripe_service.dart';
import '../../data/stripe_web_service.dart' if (dart.library.io) '../../data/stripe_web_stub.dart';
import '../../core/theme/app_theme.dart';

class PaginaCarrito extends StatelessWidget {
  const PaginaCarrito({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<ProveedorCarrito>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      extendBody: false,
      body: carrito.vacio ? _carritoVacio() : _carritoConItems(context, carrito),
    );
  }

  Widget _carritoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 52, color: Color(0xFFBDBDBD)),
          ),
          const SizedBox(height: 20),
          const Text('Tu carrito está vacío',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 8),
          const Text('Agrega productos desde la tienda',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _carritoConItems(BuildContext context, ProveedorCarrito carrito) {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 16,
            left: 20,
            right: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mi Carrito',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E))),
              TextButton.icon(
                onPressed: () => carrito.limpiar(),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('Vaciar', style: TextStyle(color: Colors.red, fontSize: 13)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: carrito.items.length,
            itemBuilder: (context, i) {
              final item = carrito.items[i];
              return _TarjetaItem(item: item, carrito: carrito);
            },
          ),
        ),

        // Resumen
        _ResumenPedido(carrito: carrito),
      ],
    );
  }
}

class _TarjetaItem extends StatelessWidget {
  final ItemCarrito item;
  final ProveedorCarrito carrito;

  const _TarjetaItem({required this.item, required this.carrito});

  @override
  Widget build(BuildContext context) {
    final precio = item.producto.precio % 1 == 0
        ? '\$${item.producto.precio.toInt()}'
        : '\$${item.producto.precio.toStringAsFixed(2)}';
    final subtotal = item.subtotal % 1 == 0
        ? '\$${item.subtotal.toInt()}'
        : '\$${item.subtotal.toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.producto.urlImagen != null
                  ? Image.network(
                      item.producto.urlImagen!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.producto.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 4),
                  Text(precio,
                      style: const TextStyle(
                          color: Color(0xFF8E8E93), fontSize: 13)),
                  const SizedBox(height: 10),
                  // Controles cantidad
                  Row(
                    children: [
                      _BtnQty(
                        icono: Icons.remove,
                        onTap: () => carrito.decrementar(item.producto.id),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${item.cantidad}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF1C1C1E))),
                      ),
                      _BtnQty(
                        icono: Icons.add,
                        onTap: () => carrito.agregar(item.producto),
                        filled: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Subtotal + eliminar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(subtotal,
                    style: TextStyle(
                        color: context.colorPrimario,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => carrito.quitar(item.producto.id),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFFBDBDBD)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFBDBDBD), size: 28),
      );
}

class _BtnQty extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  final bool filled;

  const _BtnQty({required this.icono, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled ? context.colorPrimario : Colors.white,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Icon(icono,
            size: 15, color: filled ? Colors.white : const Color(0xFF1C1C1E)),
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

  String _fmt(double v) => v % 1 == 0 ? '\$${v.toInt()}' : '\$${v.toStringAsFixed(2)}';

  Future<void> _confirmar() async {
    final perfil = context.read<ProveedorAuth>().perfil;
    if (perfil == null) {
      context.go('/login');
      return;
    }
    final metodo = await _mostrarSelectorPago();
    if (metodo == null || !mounted) return;

    setState(() => _procesando = true);
    try {
      if (metodo == 'card') {
        await _pagarConStripe(perfil.id);
      } else {
        await _crearPedido(
            clienteId: perfil.id, metodoPago: metodo, estadoPago: 'pending');
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<String?> _mostrarSelectorPago() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Método de pago',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C1C1E))),
              const SizedBox(height: 4),
              Text('Total: ${_fmt(widget.carrito.total)}',
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
              const SizedBox(height: 20),
              _OpcionPago(
                icono: Icons.credit_card_rounded,
                titulo: 'Tarjeta de crédito/débito',
                subtitulo: 'Paga ahora con Stripe',
                onTap: () => Navigator.pop(ctx, 'card'),
              ),
              const SizedBox(height: 10),
              _OpcionPago(
                icono: Icons.payments_outlined,
                titulo: 'Efectivo',
                subtitulo: 'Paga al recibir tu pedido',
                onTap: () => Navigator.pop(ctx, 'cash'),
              ),
              const SizedBox(height: 10),
              _OpcionPago(
                icono: Icons.account_balance_outlined,
                titulo: 'Transferencia bancaria',
                subtitulo: 'Te enviaremos los datos',
                onTap: () => Navigator.pop(ctx, 'transfer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pagarConStripe(String clienteId) async {
    try {
      final result =
          await ServicioStripe().crearPaymentIntent(monto: widget.carrito.total);
      final clientSecret = result['clientSecret'] as String;
      final paymentIntentId = result['paymentIntentId'] as String;

      if (kIsWeb) {
        // Pago web con Stripe.js
        if (!mounted) return;
        final confirmado = await _mostrarFormularioPagoWeb(clientSecret);
        if (!confirmado) return;
        await _crearPedido(
          clienteId: clienteId,
          metodoPago: 'card',
          estadoPago: 'paid',
          stripePaymentId: paymentIntentId,
        );
      } else {
        // Pago móvil con flutter_stripe
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Barbería',
            style: ThemeMode.light,
          ),
        );
        await Stripe.instance.presentPaymentSheet();
        await _crearPedido(
          clienteId: clienteId,
          metodoPago: 'card',
          estadoPago: 'paid',
          stripePaymentId: paymentIntentId,
        );
      }
    } on StripeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.error.localizedMessage ?? 'Pago cancelado'),
          backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<bool> _mostrarFormularioPagoWeb(String clientSecret) async {
    const containerId = 'stripe-payment-element';
    // Montar el PaymentElement de Stripe.js en el div
    await ServicioStripeWeb.montarPaymentElement(clientSecret, containerId);

    if (!mounted) return false;
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoPagoWeb(containerId: containerId),
    );
    return resultado ?? false;
  }

  Future<void> _crearPedido({
    required String clienteId,
    required String metodoPago,
    required String estadoPago,
    String? stripePaymentId,
  }) async {
    final exito = await context.read<ProveedorPedido>().realizarPedido(
          clienteId: clienteId,
          items: widget.carrito.items,
          metodoPago: metodoPago,
          estadoPago: estadoPago,
          stripePaymentId: stripePaymentId,
        );
    if (!mounted) return;
    if (exito) {
      widget.carrito.limpiar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(metodoPago == 'card'
            ? '¡Pago exitoso! Pedido confirmado.'
            : '¡Pedido realizado!'),
        backgroundColor: const Color(0xFF4ECDC4),
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              context.read<ProveedorPedido>().error ?? 'Error al realizar pedido')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.carrito.totalItems;
    final total = widget.carrito.total;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$totalItems producto${totalItems == 1 ? '' : 's'}',
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
              const Text('Total',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Text(_fmt(total),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1E))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _procesando ? null : _confirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colorPrimario,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _procesando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Confirmar pedido',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoPagoWeb extends StatefulWidget {
  final String containerId;
  const _DialogoPagoWeb({required this.containerId});

  @override
  State<_DialogoPagoWeb> createState() => _DialogoPagoWebState();
}

class _DialogoPagoWebState extends State<_DialogoPagoWeb> {
  bool _procesando = false;
  String? _error;

  Future<void> _pagar() async {
    setState(() { _procesando = true; _error = null; });
    final result = await ServicioStripeWeb.confirmarPago(
      Uri.base.toString(),
    );
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = result['error'] as String?;
        _procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pagar con tarjeta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            // Stripe.js monta el formulario aquí via HtmlElementView
            SizedBox(
              height: 200,
              child: HtmlElementView(viewType: widget.containerId),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _procesando ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _procesando ? null : _pagar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorPrimario,
                      foregroundColor: Colors.white,
                    ),
                    child: _procesando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Pagar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionPago extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _OpcionPago({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5EA), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colorPrimario.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: context.colorPrimario, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 2),
                  Text(subtitulo,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8E8E93))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}
