import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/models/service_model.dart' show ModeloServicio;
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/saved_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../data/ftp_upload_service.dart';
import '../auth/guest_wall_page.dart';
import '../cart/cart_page.dart';
import '../saved/saved_page.dart';

class PaginaProductos extends StatefulWidget {
  const PaginaProductos({super.key});

  @override
  State<PaginaProductos> createState() => _PaginaProductosState();
}

class _PaginaProductosState extends State<PaginaProductos> {
  final _ctrlBusqueda = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final esAdmin = context.read<ProveedorAuth>().perfil?.rol.isAdmin ?? false;
      context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: esAdmin);
      context.read<ProveedorServicio>().cargarServicios();
    });
  }

  @override
  void dispose() {
    _ctrlBusqueda.dispose();
    super.dispose();
  }

  Future<void> _mostrarDialogoCrear() async {
    final ctrlNombre = TextEditingController();
    final ctrlDesc = TextEditingController();
    final ctrlPrecio = TextEditingController();
    final ctrlOferta = TextEditingController();
    final ctrlStock = TextEditingController(text: '1');
    final claveFormulario = GlobalKey<FormState>();
    String? urlImagen;
    bool subiendoImagen = false;

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Selector de imagen ──────────────────
                  GestureDetector(
                    onTap: subiendoImagen
                        ? null
                        : () async {
                            setLocal(() => subiendoImagen = true);
                            final url = await ServicioFTP.seleccionarYSubirImagen(
                              nombreArchivo: ctrlNombre.text.trim(),
                              onError: (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(e)),
                                  );
                                }
                              },
                            );
                            if (ctx.mounted) {
                              setLocal(() {
                                subiendoImagen = false;
                                if (url != null) urlImagen = url;
                              });
                            }
                          },
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: kCardDark2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kTextMuted.withOpacity(0.25),
                        ),
                      ),
                      child: subiendoImagen
                          ? const Center(child: CircularProgressIndicator())
                          : urlImagen != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    urlImagen!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: kTextMuted,
                                    ),
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: kTextMuted, size: 32),
                                    SizedBox(height: 6),
                                    Text('Toca para añadir imagen',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: kTextMuted, fontSize: 12)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CampoDialogo(
                      controlador: ctrlNombre,
                      etiqueta: 'Nombre',
                      icono: Icons.label_outline,
                      validador: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlDesc,
                      etiqueta: 'Descripción',
                      icono: Icons.notes,
                      maxLineas: 2),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlPrecio,
                      etiqueta: 'Precio (\$)',
                      icono: Icons.attach_money,
                      tipoTeclado: TextInputType.number,
                      validador: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Número inválido';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlOferta,
                      etiqueta: 'Precio oferta (\$) — opcional',
                      icono: Icons.local_offer_outlined,
                      tipoTeclado: TextInputType.number,
                      validador: (v) {
                        if (v == null || v.isEmpty) return null;
                        final val = double.tryParse(v);
                        if (val == null) return 'Número inválido';
                        final precio = double.tryParse(ctrlPrecio.text);
                        if (precio != null && val >= precio) return 'Debe ser menor al precio';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlStock,
                      etiqueta: 'Stock',
                      icono: Icons.inventory_2_outlined,
                      tipoTeclado: TextInputType.number,
                      validador: (v) =>
                          (int.tryParse(v ?? '') == null)
                              ? 'Número inválido'
                              : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (claveFormulario.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (exito == true && mounted) {
      final perfil = context.read<ProveedorAuth>().perfil!;
      final proveedor = context.read<ProveedorProducto>();
      final exitoCrear = await proveedor.crearProducto(
        nombre: ctrlNombre.text.trim(),
        descripcion:
            ctrlDesc.text.trim().isEmpty ? null : ctrlDesc.text.trim(),
        precio: double.parse(ctrlPrecio.text),
        precioOferta: ctrlOferta.text.trim().isEmpty ? null : double.parse(ctrlOferta.text),
        existencias: int.parse(ctrlStock.text),
        creadoPor: perfil.id,
        urlImagen: urlImagen,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          exitoCrear
              ? const SnackBar(content: Text('Producto creado'))
              : SnackBar(
                  content: Text(proveedor.error ?? 'Error desconocido')),
        );
      }
    }

    ctrlNombre.dispose();
    ctrlDesc.dispose();
    ctrlPrecio.dispose();
    ctrlOferta.dispose();
    ctrlStock.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = context.watch<ProveedorProducto>();
    final provServicio = context.watch<ProveedorServicio>();
    final perfil = context.watch<ProveedorAuth>().perfil;
    final puedeCrear = perfil?.rol.isAdmin ?? false;
    final servicios = provServicio.servicios;

    final productosFiltrados = _busqueda.isEmpty
        ? proveedor.productos
        : proveedor.productos
            .where((p) =>
                p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                (p.descripcion?.toLowerCase().contains(_busqueda.toLowerCase()) ?? false))
            .toList();

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
                    Row(
                      children: [
                        if (Navigator.of(context).canPop())
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 20, color: Color(0xFF1C1C1E)),
                            ),
                          ),
                        const Text('Tienda',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1C1E),
                              letterSpacing: -0.5,
                            )),
                      ],
                    ),
                    _IconoCarrito(),
                  ],
                ),
              ),
            ),

            // ── Barra de búsqueda ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
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
                      borderSide: const BorderSide(color: kPrimary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),

            // ── Banner hero ──────────────────────────────────────
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
                        onTap: () => context.push('/booking/service'),
                        child: const Text(
                          'Ver todos >',
                          style: TextStyle(
                            fontSize: 13,
                            color: kPrimary,
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
                  padding: EdgeInsets.symmetric(vertical: 12),
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
                      alTap: () => context.push('/booking/service', extra: servicios[i]),
                    ),
                  ),
                ),
              ),

            // ── Título productos ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Productos Populares',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    if (proveedor.productos.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${proveedor.productos.length} productos',
                          style: const TextStyle(
                              color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Grid de productos ───────────────────────────────
            if (proveedor.cargando)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (productosFiltrados.isEmpty)
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
                        child: Icon(
                          _busqueda.isNotEmpty
                              ? Icons.search_off
                              : Icons.shopping_bag_outlined,
                          size: 48,
                          color: kTextMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _busqueda.isNotEmpty
                            ? 'Sin resultados'
                            : 'Sin productos',
                        style: const TextStyle(
                            color: Color(0xFF1C1C1E),
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _busqueda.isNotEmpty
                            ? 'No se encontró "$_busqueda"'
                            : 'Pronto habrá productos disponibles',
                        style: const TextStyle(
                            color: Color(0xFFAEAEB2), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _TarjetaProducto(
                      producto: productosFiltrados[i],
                      puedeGestionar: puedeCrear,
                      alEditar: () => _mostrarDialogoEditar(productosFiltrados[i]),
                      alEliminar: () => _confirmarEliminar(
                          productosFiltrados[i].id,
                          productosFiltrados[i].nombre,
                          proveedor),
                    ),
                    childCount: productosFiltrados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: puedeCrear
          ? FloatingActionButton(
              heroTag: null,
              onPressed: _mostrarDialogoCrear,
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _mostrarDialogoEditar(dynamic producto) async {
    final ctrlNombre = TextEditingController(text: producto.nombre);
    final ctrlDesc = TextEditingController(text: producto.descripcion ?? '');
    final ctrlPrecio =
        TextEditingController(text: producto.precio.toStringAsFixed(0));
    final ctrlOferta = TextEditingController(
        text: producto.precioOferta != null
            ? producto.precioOferta!.toStringAsFixed(0)
            : '');
    final ctrlStock =
        TextEditingController(text: producto.existencias.toString());
    final claveFormulario = GlobalKey<FormState>();
    String? urlImagen = producto.urlImagen as String?;
    bool subiendoImagen = false;

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: kPrimary, size: 22),
              SizedBox(width: 8),
              Text('Editar producto'),
            ],
          ),
          content: Form(
            key: claveFormulario,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Selector de imagen ──────────────────
                  GestureDetector(
                    onTap: subiendoImagen
                        ? null
                        : () async {
                            setLocal(() => subiendoImagen = true);
                            final url = await ServicioFTP.seleccionarYSubirImagen(
                              nombreArchivo: ctrlNombre.text.trim(),
                              onError: (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(e)),
                                  );
                                }
                              },
                            );
                            if (ctx.mounted) {
                              setLocal(() {
                                subiendoImagen = false;
                                if (url != null) urlImagen = url;
                              });
                            }
                          },
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: kCardDark2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kTextMuted.withOpacity(0.25),
                        ),
                      ),
                      child: subiendoImagen
                          ? const Center(child: CircularProgressIndicator())
                          : urlImagen != null
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          urlImagen!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.broken_image_outlined,
                                            color: kTextMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Cambiar',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: kTextMuted, size: 32),
                                    SizedBox(height: 6),
                                    Text('Toca para añadir imagen',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: kTextMuted, fontSize: 12)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CampoDialogo(
                      controlador: ctrlNombre,
                      etiqueta: 'Nombre',
                      icono: Icons.label_outline,
                      validador: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlDesc,
                      etiqueta: 'Descripción',
                      icono: Icons.notes,
                      maxLineas: 2),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlPrecio,
                      etiqueta: 'Precio (\$)',
                      icono: Icons.attach_money,
                      tipoTeclado: TextInputType.number,
                      validador: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Número inválido';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlOferta,
                      etiqueta: 'Precio oferta (\$) — opcional',
                      icono: Icons.local_offer_outlined,
                      tipoTeclado: TextInputType.number,
                      validador: (v) {
                        if (v == null || v.isEmpty) return null;
                        final val = double.tryParse(v);
                        if (val == null) return 'Número inválido';
                        final precio = double.tryParse(ctrlPrecio.text);
                        if (precio != null && val >= precio) return 'Debe ser menor al precio';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _CampoDialogo(
                      controlador: ctrlStock,
                      etiqueta: 'Stock',
                      icono: Icons.inventory_2_outlined,
                      tipoTeclado: TextInputType.number,
                      validador: (v) =>
                          (int.tryParse(v ?? '') == null)
                              ? 'Número inválido'
                              : null),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (claveFormulario.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (exito == true && mounted) {
      final proveedor = context.read<ProveedorProducto>();
      await proveedor.actualizarProducto(producto.id, {
        'name': ctrlNombre.text.trim(),
        'description':
            ctrlDesc.text.trim().isEmpty ? null : ctrlDesc.text.trim(),
        'price': double.parse(ctrlPrecio.text),
        'sale_price': ctrlOferta.text.trim().isEmpty ? null : double.parse(ctrlOferta.text),
        'stock': int.parse(ctrlStock.text),
        if (urlImagen != null) 'image_url': urlImagen,
      });
    }

    ctrlNombre.dispose();
    ctrlDesc.dispose();
    ctrlPrecio.dispose();
    ctrlOferta.dispose();
    ctrlStock.dispose();
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
  final VoidCallback alEditar;

  const _TarjetaProducto(
      {required this.producto,
      required this.puedeGestionar,
      required this.alEliminar,
      required this.alEditar});

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

    // Badge pill: oferta > agotado > null
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
                // Badge pastilla arriba-derecha
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
                  // Nombre
                  Text(producto.nombre,
                      style: const TextStyle(
                          color: Color(0xFF1C1C1E),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),

                  // Stock + precio (misma fila que rating+precio del screenshot)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                        ],
                      ),
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
                          Text(tieneOferta ? precioOferta! : precio,
                              style: TextStyle(
                                  color: tieneOferta
                                      ? const Color(0xFF1C8A4A)
                                      : const Color(0xFF1C1C1E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Botones ───────────────────────────────
                  if (puedeGestionar)
                    Row(children: [
                      Expanded(
                          child: _BotonProducto(
                              label: 'Editar',
                              onTap: alEditar,
                              outlined: true)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: _BotonProducto(
                              label: 'Eliminar',
                              onTap: alEliminar,
                              color: Colors.red.shade700)),
                    ])
                  else
                    Row(children: [
                      Expanded(
                        child: Consumer<ProveedorGuardados>(
                          builder: (ctx, _, __) {
                            return _BotonProducto(
                              label: 'Al carrito',
                              onTap: sinStock
                                  ? null
                                  : () {
                                      final auth =
                                          context.read<ProveedorAuth>();
                                      if (auth.perfil == null) {
                                        mostrarLoginRequerido(ctx);
                                        return;
                                      }
                                      context
                                          .read<ProveedorCarrito>()
                                          .agregar(producto);
                                    },
                              outlined: true,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _BotonProducto(
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
          child: Icon(Icons.inventory_2_outlined, size: 28, color: kTextMuted),
        ),
      );
}

// ── Ícono guardados ───────────────────────────────────────────
class _IconoGuardados extends StatelessWidget {
  const _IconoGuardados();

  @override
  Widget build(BuildContext context) {
    final guardados = context.watch<ProveedorGuardados>();
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaginaGuardados()),
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
            child: const Icon(Icons.favorite_border_rounded, size: 20, color: kTextSub),
          ),
          if (guardados.guardados.isNotEmpty)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${guardados.guardados.length}',
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

// ── Botón de tarjeta producto ─────────────────────────────────
class _BotonProducto extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? color;

  const _BotonProducto({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? const Color(0xFF1C1C1E);
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
