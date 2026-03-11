import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_provider.dart';
import '../../domain/models/product.dart';

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
      body: SafeArea(
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
                          size: 20, color: kText),
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
                                  fontSize: 14, color: kText),
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
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: resultados.length,
                          itemBuilder: (ctx, i) =>
                              _TarjetaResultado(producto: resultados[i]),
                        ),
            ),
          ],
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
              color: kCard,
              shape: BoxShape.circle,
              boxShadow: kNeumorphicShadows,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 48, color: kTextMuted),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Favorito
                          Consumer<ProveedorGuardados>(
                            builder: (ctx, guardados, _) {
                              final guardado =
                                  guardados.estaGuardado(producto.id);
                              return GestureDetector(
                                onTap: () =>
                                    guardados.toggleGuardado(producto.id),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: guardado
                                        ? const Color(0xFFFF3B30)
                                            .withOpacity(0.12)
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
                          // Carrito
                          if (!sinStock)
                            Consumer<ProveedorCarrito>(
                              builder: (ctx, carrito, _) {
                                final cant =
                                    carrito.cantidadProducto(producto.id);
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
          child: Icon(Icons.inventory_2_outlined, size: 32, color: kTextMuted),
        ),
      );
}
