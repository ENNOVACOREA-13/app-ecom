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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.80),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.25), Colors.black87],
        ),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              puedeGestionar ? () => _mostrarOpcionesProducto(context) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: p.urlImagen != null && p.urlImagen!.isNotEmpty
                        ? Image.network(p.urlImagen!,
                            fit: BoxFit.cover, width: double.infinity)
                        : Container(
                            color: Colors.black26,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image,
                                size: 48, color: Colors.white30),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(p.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(money.format(p.precio),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StockChip(stock: p.existencias),
                    if (!puedeGestionar)
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add_shopping_cart,
                            color: Colors.white70),
                        tooltip: 'Agregar al carrito',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

class _StockChip extends StatelessWidget {
  final int stock;
  const _StockChip({required this.stock});
  @override
  Widget build(BuildContext context) {
    final color = stock > 0 ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child:
          Text('Stock: $stock', style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
