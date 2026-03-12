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
                    childAspectRatio: 0.72,
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
            child: Icon(Icons.content_cut, color: context.colorPrimario, size: 22),
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
    final tieneOferta = producto.precioOferta != null && producto.precioOferta! < producto.precio;
    final precioOferta = tieneOferta
        ? (producto.precioOferta! % 1 == 0
            ? '\$${producto.precioOferta!.toInt()}'
            : '\$${producto.precioOferta!.toStringAsFixed(2)}')
        : null;
    final pctOff = producto.porcentajeOff;

    return Container(
      width: 140,
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                      height: 1.3,
                    ),
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
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.lineThrough)),
                            Row(
                              children: [
                                Text(tieneOferta ? precioOferta! : precio,
                                    style: TextStyle(
                                        color: tieneOferta ? const Color(0xFF1C8A4A) : context.colorPrimario,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800)),
                                if (tieneOferta && pctOff != null) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C8A4A).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('$pctOff%',
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón favorito
                          Consumer<ProveedorGuardados>(
                            builder: (ctx, guardados, _) {
                              final guardado = guardados.estaGuardado(producto.id);
                              return GestureDetector(
                                onTap: () => guardados.toggleGuardado(producto.id),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: guardado
                                        ? const Color(0xFFFF3B30).withOpacity(0.12)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: guardado
                                        ? null
                                        : Border.all(color: const Color(0xFF1C1C1E), width: 1.5),
                                  ),
                                  child: Icon(
                                    guardado
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 15,
                                    color: const Color(0xFFFF3B30),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          // Botón carrito
                          if (!sinStock)
                            Consumer<ProveedorCarrito>(
                              builder: (ctx, carrito, _) {
                                final cant = carrito.cantidadProducto(producto.id);
                                return GestureDetector(
                                  onTap: () => carrito.agregar(producto),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
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
                                            size: 15, color: ctx.colorPrimario),
                                  ),
                                );
                              },
                            ),
                        ],
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
          child: Icon(Icons.inventory_2_outlined,
              size: 28, color: kTextMuted),
        ),
      );
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
