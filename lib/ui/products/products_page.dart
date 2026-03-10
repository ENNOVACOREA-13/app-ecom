import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_theme.dart';

class PaginaProductos extends StatefulWidget {
  const PaginaProductos({super.key});

  @override
  State<PaginaProductos> createState() => _PaginaProductosState();
}

class _PaginaProductosState extends State<PaginaProductos> {
  int _filtroActivo = 0;
  final List<String> _filtros = ['Todos', 'Nuevo', 'Popular'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final esAdmin = context.read<ProveedorAuth>().perfil?.rol.isAdmin ?? false;
      context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: esAdmin);
    });
  }

  Future<void> _mostrarDialogoCrear() async {
    final ctrlNombre = TextEditingController();
    final ctrlDesc = TextEditingController();
    final ctrlPrecio = TextEditingController();
    final ctrlStock = TextEditingController(text: '1');
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_shopping_cart, color: kPrimary, size: 22),
            SizedBox(width: 8),
            Text('Nuevo producto'),
          ],
        ),
        content: Form(
          key: claveFormulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CampoDialogo(controlador: ctrlNombre, etiqueta: 'Nombre', icono: Icons.label_outline,
                  validador: (v) => (v == null || v.isEmpty) ? 'Requerido' : null),
                const SizedBox(height: 12),
                _CampoDialogo(controlador: ctrlDesc, etiqueta: 'Descripción', icono: Icons.notes, maxLineas: 2),
                const SizedBox(height: 12),
                _CampoDialogo(controlador: ctrlPrecio, etiqueta: 'Precio (\$)', icono: Icons.attach_money,
                  tipoTeclado: TextInputType.number,
                  validador: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  }),
                const SizedBox(height: 12),
                _CampoDialogo(controlador: ctrlStock, etiqueta: 'Stock', icono: Icons.inventory_2_outlined,
                  tipoTeclado: TextInputType.number,
                  validador: (v) => (int.tryParse(v ?? '') == null) ? 'Número inválido' : null),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (claveFormulario.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (exito == true && mounted) {
      final perfil = context.read<ProveedorAuth>().perfil!;
      final proveedor = context.read<ProveedorProducto>();
      final exitoCrear = await proveedor.crearProducto(
        nombre: ctrlNombre.text.trim(),
        descripcion: ctrlDesc.text.trim().isEmpty ? null : ctrlDesc.text.trim(),
        precio: double.parse(ctrlPrecio.text),
        existencias: int.parse(ctrlStock.text),
        creadoPor: perfil.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          exitoCrear
              ? const SnackBar(content: Text('Producto creado'))
              : SnackBar(content: Text(proveedor.error ?? 'Error desconocido')),
        );
      }
    }

    ctrlNombre.dispose();
    ctrlDesc.dispose();
    ctrlPrecio.dispose();
    ctrlStock.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorProducto>();
    final perfil = context.watch<ProveedorAuth>().perfil;
    final puedeCrear = perfil?.rol.isAdmin ?? false;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tienda',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.5,
                        )),
                    if (proveedor.productos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${proveedor.productos.length} productos',
                            style: const TextStyle(
                                color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
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
                      Text('Buscar productos...',
                          style: TextStyle(color: Color(0xFFAEAEB2), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Banner promocional ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                          child: const Icon(Icons.local_offer_outlined,
                              color: Colors.white, size: 32),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Productos\ndestacados',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                )),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Ver todos',
                                  style: TextStyle(
                                    color: kPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Categorías ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 14),
                    child: Text('Categoría',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        )),
                  ),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: const [
                        _ChipCategoria(icono: Icons.content_cut, etiqueta: 'Corte'),
                        SizedBox(width: 16),
                        _ChipCategoria(icono: Icons.face_retouching_natural, etiqueta: 'Barba'),
                        SizedBox(width: 16),
                        _ChipCategoria(icono: Icons.spa_outlined, etiqueta: 'Cuidado'),
                        SizedBox(width: 16),
                        _ChipCategoria(icono: Icons.colorize_outlined, etiqueta: 'Color'),
                        SizedBox(width: 16),
                        _ChipCategoria(icono: Icons.water_drop_outlined, etiqueta: 'Aceites'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Filtros + título ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Productos',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                          )),
                    ),
                    ...List.generate(_filtros.length, (i) {
                      final active = i == _filtroActivo;
                      return GestureDetector(
                        onTap: () => setState(() => _filtroActivo = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? kCard : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_filtros[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? kPrimary : const Color(0xFF6E6E73),
                              )),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Grid de productos ───────────────────────────────
            if (proveedor.cargando)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (proveedor.productos.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: kCard,
                          shape: BoxShape.circle,
                          boxShadow: kNeumorphicShadows,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            size: 48, color: kTextMuted),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sin productos',
                          style: TextStyle(
                              color: Color(0xFF1C1C1E),
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Pronto habrá productos disponibles',
                          style: TextStyle(
                              color: Color(0xFFAEAEB2), fontSize: 13)),
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
                    (context, i) => _TarjetaProducto(
                      producto: proveedor.productos[i],
                      puedeGestionar: puedeCrear,
                      alEliminar: () => _confirmarEliminar(
                          proveedor.productos[i].id,
                          proveedor.productos[i].nombre,
                          proveedor),
                    ),
                    childCount: proveedor.productos.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: puedeCrear
          ? FloatingActionButton(
              onPressed: _mostrarDialogoCrear,
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _confirmarEliminar(
      String id, String nombre, ProveedorProducto proveedor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "$nombre"?',
            style: const TextStyle(color: kTextSub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              proveedor.eliminarProducto(id);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Chip de categoría ────────────────────────────────────────
class _ChipCategoria extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  const _ChipCategoria({required this.icono, required this.etiqueta});

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
          child: Icon(icono, color: kPrimary, size: 22),
        ),
        const SizedBox(height: 6),
        Text(etiqueta,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6E6E73),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Campo de diálogo ─────────────────────────────────────────
class _CampoDialogo extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final int maxLineas;
  final TextInputType tipoTeclado;
  final String? Function(String?)? validador;

  const _CampoDialogo({
    required this.controlador,
    required this.etiqueta,
    required this.icono,
    this.maxLineas = 1,
    this.tipoTeclado = TextInputType.text,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      style: const TextStyle(color: kText),
      maxLines: maxLineas,
      keyboardType: tipoTeclado,
      validator: validador,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, size: 18, color: kTextSub),
      ),
    );
  }
}

// ── Tarjeta de producto ──────────────────────────────────────
class _TarjetaProducto extends StatelessWidget {
  final dynamic producto;
  final bool puedeGestionar;
  final VoidCallback alEliminar;

  const _TarjetaProducto(
      {required this.producto,
      required this.puedeGestionar,
      required this.alEliminar});

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
                // Botón favorito (decorativo)
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
                if (puedeGestionar)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: alEliminar,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: kCard,
                          shape: BoxShape.circle,
                          boxShadow: kNeumorphicShadowsSmall,
                        ),
                        child: const Icon(Icons.delete_outline,
                            size: 13, color: Colors.redAccent),
                      ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
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
          child: Icon(Icons.inventory_2_outlined, size: 36, color: kTextMuted),
        ),
      );
}
