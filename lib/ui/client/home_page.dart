import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/product_provider.dart';
import '../../domain/models/service_model.dart' show ModeloServicio;
import '../../domain/models/product.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key});

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorServicio>().cargarServicios();
      context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    final provServicio = context.watch<ProveedorServicio>();
    final provProducto = context.watch<ProveedorProducto>();
    final servicios = provServicio.servicios;
    final productos = provProducto.productos;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${perfil?.nombreCompleto.split(' ').first ?? ''} 👋',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1C1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Reserva tu próximo servicio',
                            style: TextStyle(
                                color: Color(0xFF6E6E73), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    AvatarRed(
                      url: perfil?.urlAvatar,
                      nombre: perfil?.nombreCompleto,
                      radio: 22,
                    ),
                  ],
                ),
              ),
            ),

            // ── Barra de búsqueda (visual) ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 14),
                      Icon(Icons.search, color: Color(0xFFAEAEB2), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Buscar...',
                        style:
                            TextStyle(color: Color(0xFFAEAEB2), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Banner de reserva ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GestureDetector(
                  onTap: () => context.push('/booking/service'),
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimary.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
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
                            child: const Icon(Icons.calendar_month_outlined,
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
                                'Nueva\nReserva',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
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
                                child: const Text(
                                  'Reservar ahora',
                                  style: TextStyle(
                                    color: kPrimary,
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

            // ── Chips de servicios (tap → booking) ───────────────
            if (servicios.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 14),
                      child: Text(
                        'Servicios',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: servicios.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => context.push(
                            '/booking/service',
                            extra: servicios[i],
                          ),
                          child: _ChipServicio(servicio: servicios[i]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Título productos ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tienda',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                    if (productos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${productos.length} productos',
                          style: const TextStyle(
                            color: kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Grid de productos ────────────────────────────────
            if (provProducto.cargando)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (productos.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: kCard,
                            shape: BoxShape.circle,
                            boxShadow: kNeumorphicShadows,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined,
                              size: 36, color: kTextMuted),
                        ),
                        const SizedBox(height: 12),
                        const Text('Sin productos disponibles',
                            style: TextStyle(
                                color: Color(0xFFAEAEB2), fontSize: 13)),
                      ],
                    ),
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
                    (context, i) => _TarjetaProducto(producto: productos[i]),
                    childCount: productos.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de servicio ─────────────────────────────────────────
class _ChipServicio extends StatelessWidget {
  final ModeloServicio servicio;
  const _ChipServicio({required this.servicio});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: kNeumorphicShadowsSmall,
          ),
          child: const Icon(Icons.content_cut, color: kPrimary, size: 22),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            servicio.nombre,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6E6E73),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta de producto ──────────────────────────────────────
class _TarjetaProducto extends StatelessWidget {
  final Producto producto;
  const _TarjetaProducto({required this.producto});

  @override
  Widget build(BuildContext context) {
    final sinStock = producto.existencias == 0;
    final precio = producto.precio % 1 == 0
        ? '\$${producto.precio.toInt()}'
        : '\$${producto.precio.toStringAsFixed(2)}';

    return Container(
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: kNeumorphicShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: producto.urlImagen != null
                      ? Image.network(
                          producto.urlImagen!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kCard.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border,
                        size: 14, color: kTextSub),
                  ),
                ),
                if (sinStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text('AGOTADO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(producto.nombre,
                      style: const TextStyle(
                          color: kText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(precio,
                          style: const TextStyle(
                              color: kPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      Text('${producto.existencias} uds',
                          style: TextStyle(
                            color: sinStock
                                ? Colors.red.shade400
                                : kTextMuted,
                            fontSize: 10,
                          )),
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
        color: kCardDark2,
        child: const Center(
          child:
              Icon(Icons.inventory_2_outlined, size: 36, color: kTextMuted),
        ),
      );
}
