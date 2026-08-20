import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../data/ftp_upload_service.dart';
import '../../domain/models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../common/skeleton.dart';
import '../common/toast.dart';

class PaginaInventario extends StatefulWidget {
  const PaginaInventario({super.key});

  @override
  State<PaginaInventario> createState() => _PaginaInventarioState();
}

class _PaginaInventarioState extends State<PaginaInventario> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: true);
    });
  }

  Future<void> _mostrarDialogoCrear() async {
    final ctrl = _CtrlsProducto();
    String? urlImagen;

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogoProducto(
        titulo: 'Nuevo producto',
        icono: Icons.add_shopping_cart,
        ctrls: ctrl,
        urlImagenInicial: null,
        onImagenCambiada: (url) => urlImagen = url,
        onConfirmar: () => Navigator.pop(ctx, true),
        onCancelar: () => Navigator.pop(ctx, false),
      ),
    );

    if (exito == true && mounted) {
      final perfil = context.read<ProveedorAuth>().perfil!;
      final prov = context.read<ProveedorProducto>();
      final ok = await prov.crearProducto(
        nombre: ctrl.nombre.text.trim(),
        descripcion: ctrl.desc.text.trim().isEmpty ? null : ctrl.desc.text.trim(),
        precio: double.parse(ctrl.precio.text),
        precioOferta: ctrl.oferta.text.trim().isEmpty ? null : double.parse(ctrl.oferta.text),
        existencias: int.parse(ctrl.stock.text),
        creadoPor: perfil.id,
        urlImagen: urlImagen,
      );
      if (mounted) {
        mostrarToast(context, ok ? 'Producto creado' : (prov.error ?? 'Error'),
            tipo: ok ? TipoToast.exito : TipoToast.error);
      }
    }
    ctrl.dispose();
  }

  Future<void> _mostrarDialogoEditar(Producto producto) async {
    final ctrl = _CtrlsProducto.desde(producto);
    String? urlImagen = producto.urlImagen;

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DialogoProducto(
        titulo: 'Editar producto',
        icono: Icons.edit_outlined,
        ctrls: ctrl,
        urlImagenInicial: producto.urlImagen,
        onImagenCambiada: (url) => urlImagen = url,
        onConfirmar: () => Navigator.pop(ctx, true),
        onCancelar: () => Navigator.pop(ctx, false),
      ),
    );

    if (exito == true && mounted) {
      final prov = context.read<ProveedorProducto>();
      await prov.actualizarProducto(producto.id, {
        'name': ctrl.nombre.text.trim(),
        'description': ctrl.desc.text.trim().isEmpty ? null : ctrl.desc.text.trim(),
        'price': double.parse(ctrl.precio.text),
        'sale_price': ctrl.oferta.text.trim().isEmpty ? null : double.parse(ctrl.oferta.text),
        'stock': int.parse(ctrl.stock.text),
        if (urlImagen != null) 'image_url': urlImagen,
      });
    }
    ctrl.dispose();
  }

  void _confirmarEliminar(Producto producto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar producto',
            style: TextStyle(color: Color(0xFF1C1C1E))),
        content: Text('¿Eliminar "${producto.nombre}"?',
            style: const TextStyle(color: kTextSub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProveedorProducto>().eliminarProducto(producto.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProveedorProducto>();

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.colorPrimario),
            tooltip: 'Nuevo producto',
            onPressed: _mostrarDialogoCrear,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.cargarProductos(esVistaAdmin: true),
          ),
        ],
      ),
      body: EnvolturaResponsiva(
        child: prov.cargando
          ? const ListaEsqueleto()
          : prov.productos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.inventory_2_outlined,
                            size: 48, color: kTextMuted),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sin productos',
                          style: TextStyle(
                              color: Color(0xFF1C1C1E),
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      const Text('Toca + para agregar el primero',
                          style: TextStyle(color: kTextMuted, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: prov.productos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = prov.productos[i];
                    return EntradaAnimada(
                      index: i,
                      child: _FilaProducto(
                        producto: p,
                        alEditar: () => _mostrarDialogoEditar(p),
                        alEliminar: () => _confirmarEliminar(p),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

// ── Fila de producto ──────────────────────────────────────────
class _FilaProducto extends StatelessWidget {
  final Producto producto;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  const _FilaProducto({
    required this.producto,
    required this.alEditar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final sinStock = producto.existencias == 0;
    final tieneOferta = producto.precioOferta != null &&
        producto.precioOferta! < producto.precio;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: producto.urlImagen != null
                  ? Image.network(
                      producto.urlImagen!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (tieneOferta) ...[
                      Text(
                        '\$${producto.precio.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\$${producto.precioOferta!.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ] else
                      Text(
                        '\$${producto.precio.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: sinStock
                            ? Colors.red.withOpacity(0.12)
                            : Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sinStock
                            ? 'Agotado'
                            : '${producto.existencias} en stock',
                        style: TextStyle(
                          color: sinStock ? Colors.red : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Acciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kTextMuted),
            color: Colors.white,
            onSelected: (v) {
              if (v == 'editar') alEditar();
              if (v == 'eliminar') alEliminar();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: kTextSub),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: Color(0xFF1C1C1E))),
                ]),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF2F2F7),
        child: const Icon(Icons.inventory_2_outlined,
            size: 28, color: kTextMuted),
      );
}

// ── Diálogo de crear/editar ───────────────────────────────────
class _DialogoProducto extends StatefulWidget {
  final String titulo;
  final IconData icono;
  final _CtrlsProducto ctrls;
  final String? urlImagenInicial;
  final void Function(String url) onImagenCambiada;
  final VoidCallback onConfirmar;
  final VoidCallback onCancelar;

  const _DialogoProducto({
    required this.titulo,
    required this.icono,
    required this.ctrls,
    required this.urlImagenInicial,
    required this.onImagenCambiada,
    required this.onConfirmar,
    required this.onCancelar,
  });

  @override
  State<_DialogoProducto> createState() => _DialogoProductoState();
}

class _DialogoProductoState extends State<_DialogoProducto> {
  final _clave = GlobalKey<FormState>();
  String? _urlImagen;
  bool _subiendoImagen = false;

  @override
  void initState() {
    super.initState();
    _urlImagen = widget.urlImagenInicial;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.ctrls;
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(widget.icono, color: context.colorPrimario, size: 22),
          const SizedBox(width: 8),
          Text(widget.titulo,
              style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 17)),
        ],
      ),
      content: Form(
        key: _clave,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen
              GestureDetector(
                onTap: _subiendoImagen
                    ? null
                    : () async {
                        setState(() => _subiendoImagen = true);
                        final url = await ServicioFTP.seleccionarYSubirImagen(
                          nombreArchivo: c.nombre.text.trim(),
                          onError: (e) {
                            if (mounted) {
                              mostrarToast(context, e, tipo: TipoToast.error);
                            }
                          },
                        );
                        if (mounted) {
                          setState(() {
                            _subiendoImagen = false;
                            if (url != null) {
                              _urlImagen = url;
                              widget.onImagenCambiada(url);
                            }
                          });
                        }
                      },
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kTextMuted.withOpacity(0.25)),
                  ),
                  child: _subiendoImagen
                      ? const Center(child: CircularProgressIndicator())
                      : _urlImagen != null
                          ? Stack(children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_urlImagen!,
                                      fit: BoxFit.cover),
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Cambiar',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                              ),
                            ])
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
              _campo(c.nombre, 'Nombre', Icons.label_outline,
                  maxLongitud: 60,
                  validador: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null),
              const SizedBox(height: 10),
              _campo(c.desc, 'Descripción', Icons.notes,
                  maxLineas: 2, maxLongitud: 300),
              const SizedBox(height: 10),
              _campo(c.precio, 'Precio (\$)', Icons.attach_money,
                  tipo: TextInputType.number,
                  maxLongitud: 10,
                  validador: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  }),
              const SizedBox(height: 10),
              _campo(c.oferta, 'Precio oferta (\$) — opcional',
                  Icons.local_offer_outlined,
                  tipo: TextInputType.number,
                  maxLongitud: 10,
                  validador: (v) {
                    if (v == null || v.isEmpty) return null;
                    final val = double.tryParse(v);
                    if (val == null) return 'Número inválido';
                    final p = double.tryParse(c.precio.text);
                    if (p != null && val >= p) return 'Debe ser menor al precio';
                    return null;
                  }),
              const SizedBox(height: 10),
              _campo(c.stock, 'Stock', Icons.inventory_2_outlined,
                  tipo: TextInputType.number,
                  maxLongitud: 6,
                  validador: (v) =>
                      (int.tryParse(v ?? '') == null) ? 'Número inválido' : null),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: widget.onCancelar,
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_clave.currentState!.validate()) widget.onConfirmar();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String etiqueta,
    IconData icono, {
    TextInputType tipo = TextInputType.text,
    int maxLineas = 1,
    int? maxLongitud,
    String? Function(String?)? validador,
  }) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Color(0xFF1C1C1E)),
      keyboardType: tipo,
      maxLines: maxLineas,
      maxLength: maxLongitud,
      validator: validador,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, size: 18, color: kTextMuted),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        counterText: '',
      ),
    );
  }
}

// ── Controladores agrupados ───────────────────────────────────
class _CtrlsProducto {
  final nombre = TextEditingController();
  final desc = TextEditingController();
  final precio = TextEditingController();
  final oferta = TextEditingController();
  final stock = TextEditingController(text: '1');

  _CtrlsProducto();

  _CtrlsProducto.desde(Producto p) {
    nombre.text = p.nombre;
    desc.text = p.descripcion ?? '';
    precio.text = p.precio.toStringAsFixed(0);
    oferta.text = p.precioOferta?.toStringAsFixed(0) ?? '';
    stock.text = p.existencias.toString();
  }

  void dispose() {
    nombre.dispose();
    desc.dispose();
    precio.dispose();
    oferta.dispose();
    stock.dispose();
  }
}
