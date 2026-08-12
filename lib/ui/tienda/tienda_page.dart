import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/product_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/app_context.dart';
import '../../domain/services/role_service.dart';
import '../theme/app_theme.dart';

class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});
  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  final _repo = RepositorioProducto();
  Future<List<Producto>>? _future;
  int _lastVersion = -1;

  @override
  void initState() {
    super.initState();
    print('🏪 TiendaPage initState - Cargando productos...');
    _cargarProductos();
  }

  void _cargarProductos() {
    print('🔄 Recargando productos...');
    setState(() {
      _future = _repo.obtenerTodosLosProductos();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final contexto = context.watch<ContextoApp>();

    print(
        '👀 didChangeDependencies - Version: ${contexto.productosVersion}, Last: $_lastVersion');
    // Recargar si cambió la versión de productos
    if (contexto.productosVersion != _lastVersion) {
      print('🆕 Nueva versión detectada, recargando...');
      _lastVersion = contexto.productosVersion;
      _cargarProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rol = context.watch<ContextoApp>().rol;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar:
          AppBar(backgroundColor: AppColors.black, title: const Text('Tienda')),
      body: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (ctx, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = s.data ?? const <Producto>[];
          if (items.isEmpty) {
            return const Center(
                child: Text('Sin productos',
                    style: TextStyle(color: Colors.white70)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              _cargarProductos();
              await _future;
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.68),
                itemCount: items.length,
                itemBuilder: (_, i) => _ProductCard(
                  p: items[i],
                  rol: rol,
                  repo: _repo,
                  onChanged: _cargarProductos,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Producto p;
  final String rol;
  final RepositorioProducto repo;
  final VoidCallback onChanged;

  const _ProductCard({
    required this.p,
    required this.rol,
    required this.repo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final puedeGestionar = RoleService.puedeGestionarProductos(rol);
    final tieneOferta = p.precioOferta != null && p.precioOferta! < p.precio;
    final agotado = p.existencias == 0;

    // Badge label y color
    String? badgeLabel;
    Color badgeColor = Colors.black87;
    if (agotado) {
      badgeLabel = 'Agotado';
      badgeColor = Colors.red.shade700;
    } else if (tieneOferta) {
      badgeLabel = '−${p.porcentajeOff}%';
      badgeColor = Colors.green.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Imagen + badge ──────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: const Color(0xFFF3F3F3),
                  child: p.urlImagen != null && p.urlImagen!.isNotEmpty
                      ? Image.network(
                          p.urlImagen!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: Color(0xFFBBBBBB),
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: Color(0xFFCCCCCC),
                        ),
                ),
              ),
              if (badgeLabel != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Info ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    p.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Stock + precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            agotado
                                ? Icons.remove_circle_outline
                                : Icons.check_circle_outline,
                            size: 12,
                            color: agotado
                                ? Colors.red.shade400
                                : Colors.green.shade500,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            agotado ? 'Sin stock' : '${p.existencias} uds.',
                            style: TextStyle(
                              fontSize: 11,
                              color: agotado
                                  ? Colors.red.shade400
                                  : Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (tieneOferta)
                            Text(
                              money.format(p.precio),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black38,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            money.format(
                                tieneOferta ? p.precioOferta! : p.precio),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Botones ──────────────────────────────
                  if (puedeGestionar)
                    Row(
                      children: [
                        Expanded(
                          child: _BotonTarjeta(
                            label: 'Editar',
                            onTap: () => _mostrarOpcionesProducto(context),
                            outlined: true,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _BotonTarjeta(
                            label: 'Eliminar',
                            onTap: () => _confirmarEliminacion(context),
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _BotonTarjeta(
                            label: 'Al carrito',
                            onTap: agotado ? null : () {},
                            outlined: true,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _BotonTarjeta(
                            label: 'Comprar',
                            onTap: agotado ? null : () {},
                          ),
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

  void _mostrarOpcionesProducto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              p.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Editar producto',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _editarProducto(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Eliminar producto',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmarEliminacion(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _editarProducto(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController(text: p.nombre);
    final precioController = TextEditingController(text: p.precio.toString());
    final stockController =
        TextEditingController(text: p.existencias.toString());

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Producto',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre
                TextFormField(
                  controller: nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.label, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),
                // Precio
                TextFormField(
                  controller: precioController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Precio',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (num.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Stock
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Stock',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                        const Icon(Icons.inventory, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (int.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == true && context.mounted) {
      try {
        await repo.actualizarProducto(p.id, {
          'name': nombreController.text.trim(),
          'price': num.tryParse(precioController.text) ?? 0,
          'stock': int.tryParse(stockController.text) ?? 0,
        });

        if (context.mounted) {
          context.read<ContextoApp>().notificarProductoCreado();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          onChanged();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }

    nombreController.dispose();
    precioController.dispose();
    stockController.dispose();
  }

  void _confirmarEliminacion(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar eliminación',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${p.nombre}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      try {
        await repo.eliminarProducto(p.id);

        if (context.mounted) {
          context.read<ContextoApp>().notificarProductoCreado();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          onChanged();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}

class _BotonTarjeta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? color;

  const _BotonTarjeta({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Colors.black87;
    return SizedBox(
      height: 32,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: onTap == null ? Colors.black26 : bg),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: onTap == null ? Colors.black26 : bg,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }
}
