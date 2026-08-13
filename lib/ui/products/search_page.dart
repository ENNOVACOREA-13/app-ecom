import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/cart_fly_animation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_provider.dart';
import '../../domain/models/product.dart';
import '../common/app_widgets.dart';
import 'product_detail_page.dart';

class PaginaBusquedaProductos extends StatefulWidget {
  const PaginaBusquedaProductos({super.key});

  @override
  State<PaginaBusquedaProductos> createState() =>
      _PaginaBusquedaProductosState();
}

class _PaginaBusquedaProductosState extends State<PaginaBusquedaProductos> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(List<Producto> todos) {
    if (_query.trim().isEmpty) return todos;
    final q = _query.toLowerCase();
    return todos
        .where((p) =>
            p.nombre.toLowerCase().contains(q) ||
            (p.descripcion?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provProducto = context.watch<ProveedorProducto>();
    final resultados = _filtrar(provProducto.productos);

    return Scaffold(
      backgroundColor: kBackground,
      body: EnvolturaResponsiva(
        child: SafeArea(
        child: Column(
          children: [
            // ── Barra de búsqueda ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Color(0xFF1C1C1E)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search,
                              color: Color(0xFFAEAEB2), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF1C1C1E)),
                              decoration: const InputDecoration(
                                hintText: 'Buscar productos...',
                                hintStyle:
                                    TextStyle(color: Color(0xFFAEAEB2)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                setState(() => _query = '');
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.close,
                                    size: 18, color: Color(0xFFAEAEB2)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Contador de resultados ─────────────────────────────
            if (_query.isNotEmpty && !provProducto.cargando)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    resultados.isEmpty
                        ? 'Sin resultados para "$_query"'
                        : '${resultados.length} resultado${resultados.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6E6E73)),
                  ),
                ),
              ),

            // ── Contenido ─────────────────────────────────────────
            Expanded(
              child: provProducto.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : resultados.isEmpty
                      ? _EstadoVacio(query: _query)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 230,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: resultados.length,
                          itemBuilder: (ctx, i) =>
                              _TarjetaResultado(producto: resultados[i]),
                        ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────
class _EstadoVacio extends StatelessWidget {
  final String query;
  const _EstadoVacio({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 48, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 20),
          Text(
            query.isEmpty ? 'Escribe para buscar' : 'Sin resultados',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E)),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'No encontramos productos para\n"$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFAEAEB2), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tarjeta de resultado ───────────────────────────────────────
class _TarjetaResultado extends StatelessWidget {
  final Producto producto;
  const _TarjetaResultado({required this.producto});

  @override
  Widget build(BuildContext context) {
    final enCarrito = context.watch<ProveedorCarrito>().cantidadProducto(producto.id);
    final agotado = producto.existencias == 0;
    final sinStock = agotado || enCarrito >= producto.existencias;
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
                            ? Image.network(
                                producto.urlImagen!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      // Badge arriba-izquierda
                      if (badgeText != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                  color: badgeTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      // Corazón arriba-derecha
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer<ProveedorGuardados>(
                          builder: (ctx, guardados, _) {
                            final guardado = guardados.estaGuardado(producto.id);
                            return GestureDetector(
                              onTap: () => guardados.toggleGuardado(producto.id),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: context.colorPrimario,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
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
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Info ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    producto.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  PildoraPrecioCarrito(
                    precio: tieneOferta ? precioOferta! : precio,
                    precioTachado: tieneOferta ? precio : null,
                    sinStock: sinStock,
                    onTap: sinStock
                        ? null
                        : () {
                            final perfil = context.read<ProveedorAuth>().perfil;
                            if (perfil == null) return;
                            AnimacionCarrito.volar(
                              contextOrigen: context,
                              imagenUrl: producto.urlImagen,
                            );
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
