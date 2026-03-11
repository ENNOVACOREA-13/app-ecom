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
                    childAspectRatio: 0.72,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen — cuadrada 1:1
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: producto.urlImagen != null
                        ? Image.network(
                            producto.urlImagen!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                if (sinStock)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('AGOTADO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                // Botón quitar guardado
                Positioned(
                  top: 6,
                  right: 6,
                  child: Consumer<ProveedorGuardados>(
                    builder: (ctx, guardados, _) => GestureDetector(
                      onTap: () => guardados.toggleGuardado(producto.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: kNeumorphicShadowsSmall,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                        color: Color(0xFF1C1C1E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tieneOferta)
                              Text(precio,
                                  style: const TextStyle(
                                      color: Color(0xFFAEAEB2),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.lineThrough)),
                            Row(
                              children: [
                                Text(tieneOferta ? precioOferta! : precio,
                                    style: TextStyle(
                                        color: tieneOferta ? const Color(0xFF1C8A4A) : context.colorPrimario,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                if (tieneOferta && pctOff != null) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C8A4A).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('$pctOff% OFF',
                                        style: const TextStyle(
                                            color: Color(0xFF1C8A4A),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!sinStock)
                        Consumer<ProveedorCarrito>(
                          builder: (ctx, carrito, _) {
                            final cant = carrito.cantidadProducto(producto.id);
                            return GestureDetector(
                              onTap: () => carrito.agregar(producto),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cant > 0 ? ctx.colorPrimario : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: cant > 0 ? null : Border.all(color: ctx.colorPrimario, width: 1.5),
                                ),
                                child: cant > 0
                                    ? Text('$cant',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800))
                                    : Icon(Icons.add,
                                        size: 13, color: ctx.colorPrimario),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
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
