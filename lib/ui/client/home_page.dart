import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/product_provider.dart';
import '../../domain/models/service_model.dart' show ModeloServicio;
import '../../domain/models/product.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_provider.dart';
import '../cart/cart_page.dart';
import '../common/app_widgets.dart';
import '../auth/guest_wall_page.dart';

class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key});

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  final _ctrlBusqueda = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorServicio>().cargarServicios();
      context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: false);
    });
  }

  @override
  void dispose() {
    _ctrlBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    final provServicio = context.watch<ProveedorServicio>();
    final provProducto = context.watch<ProveedorProducto>();
    final servicios = provServicio.servicios;
    final todosProductos = provProducto.productos;
    final productos = _busqueda.isEmpty
        ? todosProductos
        : todosProductos
            .where((p) =>
                p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                (p.descripcion?.toLowerCase().contains(_busqueda.toLowerCase()) ?? false))
            .toList();
    final nombre = perfil?.nombreCompleto.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header fijo ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombre 👋',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Encuentra tu próximo servicio',
                          style: TextStyle(
                              color: Color(0xFF6E6E73), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  _IconoCarrito(),
                  const SizedBox(width: 12),
                  AvatarRed(
                    url: perfil?.urlAvatar,
                    nombre: perfil?.nombreCompleto,
                    radio: 22,
                  ),
                ],
              ),
            ),

            // ── Barra de búsqueda fija ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _ctrlBusqueda,
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  hintStyle: const TextStyle(color: Color(0xFFAEAEB2), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFAEAEB2), size: 20),
                  suffixIcon: _busqueda.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFFAEAEB2), size: 18),
                          onPressed: () {
                            _ctrlBusqueda.clear();
                            setState(() => _busqueda = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.colorPrimario, width: 1.5),
                  ),
                ),
              ),
            ),

            // ── Contenido scrolleable ─────────────────────────────
            Expanded(
              child: CustomScrollView(
                slivers: [

            // ── Banner hero ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GestureDetector(
                  onTap: () {
                    if (context.read<ProveedorAuth>().perfil == null) {
                      mostrarLoginRequerido(context);
                      return;
                    }
                    context.push('/booking/service');
                  },
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.colorPrimario, context.colorPrimario.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: context.colorPrimario.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          top: 20,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.content_cut,
                                color: Colors.white, size: 32),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¡TU MEJOR LOOK,\nUN TAP DE DISTANCIA!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Reservar ahora',
                                  style: TextStyle(
                                    color: context.colorPrimario,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Categorías de servicios — título ─────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Categorías de Servicios',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    if (servicios.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          if (context.read<ProveedorAuth>().perfil == null) {
                            mostrarLoginRequerido(context);
                            return;
                          }
                          context.push('/booking/service');
                        },
                        child: Text(
                          'Ver todos >',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colorPrimario,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Chips de servicios (horizontal) ──────────────────
            if (provServicio.cargando)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (servicios.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: servicios.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => _ChipServicio(
                      servicio: servicios[i],
                      alTap: () {
                        if (context.read<ProveedorAuth>().perfil == null) {
                          mostrarLoginRequerido(context);
                          return;
                        }
                        context.push('/booking/service', extra: servicios[i]);
                      },
                    ),
                  ),
                ),
              ),

            // ── Productos populares — título ──────────────────────
            if (todosProductos.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _busqueda.isEmpty ? 'Productos Populares' : 'Resultados',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.colorPrimario.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${productos.length} productos',
                          style: TextStyle(
                            color: context.colorPrimario,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Grid de productos (2 columnas) ───────────────────
            if (productos.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _TarjetaProductoH(producto: productos[i]),
                    childCount: productos.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
            ),       // cierra Expanded
          ],          // cierra Column
        ),
      ),
    );
  }
}

// ── Chip circular de servicio ─────────────────────────────────
class _ChipServicio extends StatelessWidget {
  final ModeloServicio servicio;
  final VoidCallback alTap;
  const _ChipServicio({required this.servicio, required this.alTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: kCard,
              shape: BoxShape.circle,
              boxShadow: kNeumorphicShadowsSmall,
            ),
            child: const Icon(Icons.content_cut, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              servicio.nombre,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kTextSub,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de producto horizontal (tarjeta oscura) ───────────
class _TarjetaProductoH extends StatelessWidget {
  final Producto producto;
  const _TarjetaProductoH({required this.producto});

  @override
  Widget build(BuildContext context) {
    final sinStock = producto.existencias == 0;
    final precio = producto.precio % 1 == 0
        ? '\$${producto.precio.toInt()}'
        : '\$${producto.precio.toStringAsFixed(2)}';
    final tieneOferta = producto.precioOferta != null &&
        producto.precioOferta! < producto.precio;
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagen + badge ───────────────────────────────
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
                            ? Image.network(producto.urlImagen!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder())
                            : _placeholder(),
                      ),
                // Corazón arriba-izquierda
                Positioned(
                  top: 8,
                  left: 8,
                  child: Consumer<ProveedorGuardados>(
                    builder: (ctx, guardados, _) {
                      final guardado = guardados.estaGuardado(producto.id);
                      return GestureDetector(
                        onTap: () => guardados.toggleGuardado(producto.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            guardado
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (badgeText != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
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
                      child: Text(badgeText,
                          style: TextStyle(
                              color: badgeTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                    ],          // Stack.children
                  ),            // Stack
                ),              // ClipRRect
              ),                // Container
            ),                  // AspectRatio
          ),                    // Padding

          // ── Info ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Stock + precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          sinStock
                              ? Icons.remove_circle_outline
                              : Icons.check_circle_outline,
                          size: 11,
                          color: sinStock
                              ? Colors.red.shade400
                              : Colors.green.shade500,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          sinStock
                              ? 'Sin stock'
                              : '${producto.existencias} uds.',
                          style: TextStyle(
                              fontSize: 10,
                              color: sinStock
                                  ? Colors.red.shade400
                                  : Colors.green.shade600,
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tieneOferta)
                            Text(precio,
                                style: const TextStyle(
                                    color: Color(0xFFAEAEB2),
                                    fontSize: 9,
                                    decoration: TextDecoration.lineThrough)),
                          Text(
                            tieneOferta ? precioOferta! : precio,
                            style: TextStyle(
                                color: tieneOferta
                                    ? const Color(0xFF1C8A4A)
                                    : const Color(0xFF1C1C1E),
                                fontSize: 14,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // ── Botones ───────────────────────────────
                  Row(children: [
                    Expanded(
                      child: Consumer<ProveedorGuardados>(
                        builder: (ctx, guardados, _) => _BotonTarjetaH(
                          label: 'Al carrito',
                          onTap: sinStock
                              ? null
                              : () => context
                                  .read<ProveedorCarrito>()
                                  .agregar(producto),
                          outlined: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _BotonTarjetaH(
                        label: 'Comprar',
                        onTap: sinStock ? null : () {},
                      ),
                    ),
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
          child: Icon(Icons.inventory_2_outlined,
              size: 28, color: kTextMuted),
        ),
      );
}

// ── Botón de tarjeta producto ─────────────────────────────────
class _BotonTarjetaH extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  const _BotonTarjetaH({
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

// ── Ícono carrito con badge ───────────────────────────────────
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
            child: const Icon(Icons.shopping_cart_outlined,
                size: 20, color: kTextSub),
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
