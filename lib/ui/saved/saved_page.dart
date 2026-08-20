import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/cart_fly_animation.dart';
import '../../core/entrada_animada.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/saved_provider.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_page.dart';
import '../common/app_widgets.dart';
import '../common/skeleton.dart';
import '../products/product_detail_page.dart';

class PaginaGuardados extends StatefulWidget {
  const PaginaGuardados({super.key});

  @override
  State<PaginaGuardados> createState() => _PaginaGuardadosState();
}

class _PaginaGuardadosState extends State<PaginaGuardados> {
  final _carritoKey = GlobalKey();

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
      body: EnvolturaResponsiva(
        child: SafeArea(
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
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.3,
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
                    _IconoCarrito(key: _carritoKey),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Contenido
            if (guardadosProv.cargando || productosProv.cargando)
              const SliverToBoxAdapter(child: ListaEsqueleto())
            else if (productosGuardados.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F2F7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_border_rounded,
                          size: 52,
                          color: Color(0xFF8E8E93),
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
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = productosGuardados[i];
                      return EntradaAnimada(
                        index: i,
                        child: _TarjetaGuardado(producto: p, carritoKey: _carritoKey),
                      );
                    },
                    childCount: productosGuardados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _TarjetaGuardado extends StatelessWidget {
  final dynamic producto;
  final GlobalKey? carritoKey;
  const _TarjetaGuardado({required this.producto, this.carritoKey});

  @override
  Widget build(BuildContext context) {
    final enCarrito = context.watch<ProveedorCarrito>().cantidadProducto(producto.id);
    final agotado = producto.existencias == 0;
    final sinStock = agotado || enCarrito >= producto.existencias;
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
    } else if (agotado) {
      badgeText = 'Agotado';
      badgeTextColor = Colors.red.shade700;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaginaDetalleProducto(producto: producto)),
      ),
      child: Container(
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
                      if (badgeText != null)
                        Positioned(
                          top: 8, left: 8,
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
                      // Corazón arriba-derecha (siempre guardado en esta pantalla, toca para quitar)
                      Positioned(
                        top: 8, right: 8,
                        child: Consumer<ProveedorGuardados>(
                          builder: (ctx, guardados, _) => GestureDetector(
                            onTap: () => guardados.toggleGuardado(producto.id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: context.colorPrimario,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4, offset: const Offset(0, 1))],
                              ),
                              child: const Icon(Icons.favorite_rounded, size: 16, color: Colors.white),
                            ),
                          ),
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
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(producto.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  PildoraPrecioCarrito(
                    precio: tieneOferta ? precioOferta! : precio,
                    precioTachado: tieneOferta ? precio : null,
                    sinStock: sinStock,
                    onTap: sinStock
                        ? null
                        : () {
                            AnimacionCarrito.volar(contextOrigen: context, destinoKey: carritoKey, imagenUrl: producto.urlImagen);
                            context.read<ProveedorCarrito>().agregar(producto);
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

class _IconoCarrito extends StatelessWidget {
  const _IconoCarrito({super.key});

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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: kNeumorphicShadowsSmall,
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 20, color: Color(0xFF6E6E73)),
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
