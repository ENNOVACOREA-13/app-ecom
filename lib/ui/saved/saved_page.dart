import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/saved_provider.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_page.dart';

class PaginaGuardados extends StatefulWidget {
  const PaginaGuardados({super.key});

  @override
  State<PaginaGuardados> createState() => _PaginaGuardadosState();
}

class _PaginaGuardadosState extends State<PaginaGuardados> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perfil = context.read<ProveedorAuth>().perfil;
      if (perfil != null) {
        context.read<ProveedorGuardados>().cargar(perfil.id);
        context.read<ProveedorProducto>().cargarProductos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final guardadosProv = context.watch<ProveedorGuardados>();
    final productosProv = context.watch<ProveedorProducto>();

    final productosGuardados = productosProv.productos
        .where((p) => guardadosProv.estaGuardado(p.id))
        .toList();

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guardados',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (productosGuardados.isNotEmpty)
                          Text(
                            '${productosGuardados.length} producto${productosGuardados.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6E6E73),
                            ),
                          ),
                      ],
                    ),
                    _IconoCarrito(),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Contenido
            if (guardadosProv.cargando || productosProv.cargando)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (productosGuardados.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: const BoxDecoration(
                          color: kCard,
                          shape: BoxShape.circle,
                          boxShadow: kNeumorphicShadows,
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 52,
                          color: kTextMuted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sin guardados aún',
                        style: TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Toca el corazón en cualquier producto\npara guardarlo aquí',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFAEAEB2),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = productosGuardados[i];
                      return _TarjetaGuardado(producto: p);
                    },
                    childCount: productosGuardados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaGuardado extends StatelessWidget {
  final dynamic producto;
  const _TarjetaGuardado({required this.producto});

  @override
  Widget build(BuildContext context) {
    final sinStock = producto.existencias == 0;
    final precio = producto.precio % 1 == 0
        ? '\$${producto.precio.toInt()}'
        : '\$${producto.precio.toStringAsFixed(2)}';
    final tieneOferta = producto.precioOferta != null && producto.precioOferta! < producto.precio;
    final precioOferta = tieneOferta
        ? (producto.precioOferta! % 1 == 0
            ? '\$${producto.precioOferta!.toInt()}'
            : '\$${producto.precioOferta!.toStringAsFixed(2)}')
        : null;
    final pctOff = producto.porcentajeOff;

    String? badgeText;
    Color badgeTextColor = Colors.black87;
    if (tieneOferta && pctOff != null) {
      badgeText = '−$pctOff%';
      badgeTextColor = const Color(0xFF1C8A4A);
    } else if (sinStock) {
      badgeText = 'Agotado';
      badgeTextColor = Colors.red.shade700;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: producto.urlImagen != null
                            ? Image.network(producto.urlImagen!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                            : _placeholder(),
                      ),
                      // Corazón arriba-izquierda (rojo = guardado, toca para quitar)
                      Positioned(
                        top: 8, left: 8,
                        child: Consumer<ProveedorGuardados>(
                          builder: (ctx, guardados, _) => GestureDetector(
                            onTap: () => guardados.toggleGuardado(producto.id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 1))],
                              ),
                              child: const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFFF3B30)),
                            ),
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 1))],
                            ),
                            child: Text(badgeText, style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre,
                      style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(sinStock ? Icons.remove_circle_outline : Icons.check_circle_outline,
                            size: 11, color: sinStock ? Colors.red.shade400 : Colors.green.shade500),
                        const SizedBox(width: 3),
                        Text(sinStock ? 'Sin stock' : '${producto.existencias} uds.',
                            style: TextStyle(fontSize: 10, color: sinStock ? Colors.red.shade400 : Colors.green.shade600, fontWeight: FontWeight.w500)),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                        if (tieneOferta) Text(precio, style: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 9, decoration: TextDecoration.lineThrough)),
                        Text(tieneOferta ? precioOferta! : precio,
                            style: TextStyle(color: tieneOferta ? const Color(0xFF1C8A4A) : const Color(0xFF1C1C1E), fontSize: 14, fontWeight: FontWeight.w800)),
                      ]),
                    ],
                  ),
                  const Spacer(),
                  Row(children: [
                    Expanded(child: _BotonGuardado(label: 'Al carrito', onTap: sinStock ? null : () => context.read<ProveedorCarrito>().agregar(producto), outlined: true)),
                    const SizedBox(width: 6),
                    Expanded(child: _BotonGuardado(label: 'Comprar', onTap: sinStock ? null : () {})),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF2F2F7),
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 32, color: kTextMuted),
        ),
      );
}

class _BotonGuardado extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  const _BotonGuardado({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1C1C1E);
    return SizedBox(
      height: 34,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(
                    color: onTap == null ? Colors.black26 : bg, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: onTap == null ? Colors.black26 : bg,
                      fontWeight: FontWeight.w700)),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: onTap == null ? Colors.black26 : bg,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
    );
  }
}

class _IconoCarrito extends StatelessWidget {
  const _IconoCarrito();

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
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: kCard,
              shape: BoxShape.circle,
              boxShadow: kNeumorphicShadowsSmall,
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 20, color: kTextSub),
          ),
          if (carrito.totalItems > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${carrito.totalItems}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
