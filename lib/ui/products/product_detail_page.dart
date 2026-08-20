import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/cart_fly_animation.dart';
import '../../core/entrada_animada.dart';
import '../../domain/models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_provider.dart';
import '../auth/guest_wall_page.dart';
import '../cart/cart_page.dart';
import '../common/toast.dart';

class PaginaDetalleProducto extends StatefulWidget {
  final Producto producto;
  const PaginaDetalleProducto({super.key, required this.producto});

  @override
  State<PaginaDetalleProducto> createState() => _PaginaDetalleProductoState();
}

class _PaginaDetalleProductoState extends State<PaginaDetalleProducto> {
  int _cantidad = 1;
  final _carritoKey = GlobalKey();

  String _formatearPrecio(double valor) =>
      valor % 1 == 0 ? '\$${valor.toInt()}' : '\$${valor.toStringAsFixed(2)}';

  void _agregarAlCarrito() {
    final auth = context.read<ProveedorAuth>();
    if (auth.perfil == null) {
      mostrarLoginRequerido(context);
      return;
    }
    final carrito = context.read<ProveedorCarrito>();
    final agregado = carrito.agregar(widget.producto, cantidad: _cantidad);
    if (agregado) {
      AnimacionCarrito.volar(
        contextOrigen: context,
        destinoKey: _carritoKey,
        imagenUrl: widget.producto.urlImagen,
      );
    }
    mostrarToast(
      context,
      agregado
          ? '${widget.producto.nombre} agregado al carrito'
          : 'Ya tienes en el carrito todo el stock disponible de "${widget.producto.nombre}"',
      tipo: agregado ? TipoToast.exito : TipoToast.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final enCarrito = context.watch<ProveedorCarrito>().cantidadProducto(producto.id);
    final maxSeleccionable = (producto.existencias - enCarrito).clamp(0, producto.existencias);
    final sinStock = maxSeleccionable == 0;
    final agotado = producto.existencias == 0;
    if (_cantidad > maxSeleccionable && maxSeleccionable > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _cantidad = maxSeleccionable);
      });
    }
    final tieneOferta =
        producto.precioOferta != null && producto.precioOferta! < producto.precio;
    final precio = _formatearPrecio(tieneOferta ? producto.precioOferta! : producto.precio);
    final precioTachado = tieneOferta ? _formatearPrecio(producto.precio) : null;
    final pctOff = producto.porcentajeOff;

    return Scaffold(
      backgroundColor: kBackground,
      body: EnvolturaFormularioResponsivo(
        anchoMaximo: 520,
        child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: EntradaAnimada(
                  index: 0,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Imagen ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: AspectRatio(
                        aspectRatio: 1.05,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: producto.urlImagen != null
                                      ? Image.network(producto.urlImagen!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _placeholder())
                                      : _placeholder(),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: _BotonCircular(
                                    icono: Icons.arrow_back_ios_new_rounded,
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Row(
                                    children: [
                                      Consumer<ProveedorGuardados>(
                                        builder: (ctx, guardados, _) {
                                          final guardado = guardados.estaGuardado(producto.id);
                                          return _BotonCircular(
                                            icono: guardado
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            iconoColor: guardado ? Colors.red : null,
                                            onTap: () => guardados.toggleGuardado(producto.id),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _IconoCarritoDetalle(key: _carritoKey),
                                    ],
                                  ),
                                ),
                                if (tieneOferta && pctOff != null)
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text('−$pctOff%',
                                          style: const TextStyle(
                                              color: Color(0xFF1C8A4A),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  )
                                else if (agotado)
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.12),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text('Agotado',
                                          style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Nombre + precio + cantidad ────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(producto.nombre,
                              style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(precio,
                                  style: TextStyle(
                                      color: tieneOferta
                                          ? const Color(0xFF1C8A4A)
                                          : context.colorPrimario,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800)),
                              if (precioTachado != null) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(precioTachado,
                                      style: const TextStyle(
                                          color: Color(0xFFAEAEB2),
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough)),
                                ),
                              ],
                              const Spacer(),
                              _SelectorCantidad(
                                cantidad: _cantidad,
                                maximo: maxSeleccionable,
                                onCambiar: (v) => setState(() => _cantidad = v),
                              ),
                            ],
                          ),
                          if (!sinStock) ...[
                            const SizedBox(height: 6),
                            Text(
                                enCarrito > 0
                                    ? '${producto.existencias} disponibles · $enCarrito ya en tu carrito'
                                    : '${producto.existencias} disponibles',
                                style: const TextStyle(color: kTextSub, fontSize: 12)),
                          ] else if (enCarrito > 0) ...[
                            const SizedBox(height: 6),
                            const Text('Ya tienes todo el stock disponible en tu carrito',
                                style: TextStyle(color: Colors.orange, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),

                    if (producto.descripcion != null &&
                        producto.descripcion!.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: Color(0xFFE5E5EA), height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Descripción',
                                style: TextStyle(
                                    color: Color(0xFF1C1C1E),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text(producto.descripcion!,
                                style: const TextStyle(
                                    color: Color(0xFF6E6E73), fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ] else
                      const SizedBox(height: 12),
                  ],
                ),
                ),
              ),
            ),

            // ── Barra inferior: agregar al carrito ────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sinStock ? Colors.black26 : context.colorPrimario,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: sinStock ? null : _agregarAlCarrito,
                    child: Text(
                      !sinStock
                          ? 'Agregar al carrito'
                          : (agotado ? 'Agotado' : 'Ya está en tu carrito'),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF2F2F7),
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 48, color: kTextMuted),
        ),
      );
}

// ── Ícono de carrito con badge (destino de la animación) ────────────
class _IconoCarritoDetalle extends StatelessWidget {
  const _IconoCarritoDetalle({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<ProveedorCarrito>();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaginaCarrito()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 17, color: Color(0xFF1C1C1E)),
          ),
          if (carrito.totalItems > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: context.colorPrimario,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '${carrito.totalItems}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Botón circular flotante (back / favorito) ─────────────────────
class _BotonCircular extends StatelessWidget {
  final IconData icono;
  final Color? iconoColor;
  final VoidCallback onTap;

  const _BotonCircular({required this.icono, required this.onTap, this.iconoColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icono, size: 17, color: iconoColor ?? const Color(0xFF1C1C1E)),
      ),
    );
  }
}

// ── Selector de cantidad ────────────────────────────────────────
class _SelectorCantidad extends StatelessWidget {
  final int cantidad;
  final int maximo;
  final ValueChanged<int> onCambiar;

  const _SelectorCantidad(
      {required this.cantidad, required this.maximo, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _botonPaso(
            icono: Icons.remove,
            onTap: cantidad > 1 ? () => onCambiar(cantidad - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text('$cantidad',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF1C1C1E), fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          _botonPaso(
            icono: Icons.add,
            onTap: cantidad < maximo ? () => onCambiar(cantidad + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _botonPaso({required IconData icono, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.black12 : const Color(0xFF1C1C1E),
          shape: BoxShape.circle,
        ),
        child: Icon(icono, size: 15, color: Colors.white),
      ),
    );
  }
}
