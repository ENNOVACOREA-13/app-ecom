import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../core/service_icons.dart';
import '../../data/ftp_upload_service.dart';
import '../../domain/models/product_category.dart';
import '../../providers/product_category_provider.dart';
import '../../providers/product_provider.dart';
import '../common/app_widgets.dart';
import '../common/toast.dart';

class PaginaCategoriasProducto extends StatefulWidget {
  const PaginaCategoriasProducto({super.key});

  @override
  State<PaginaCategoriasProducto> createState() => _PaginaCategoriasProductoState();
}

class _PaginaCategoriasProductoState extends State<PaginaCategoriasProducto> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorCategoriasProducto>().cargarCategorias();
      context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: true);
    });
  }

  Future<String?> _elegirIcono(String? actual) async {
    String consulta = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final resultados = buscarIconosServicio(consulta);
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Elige un icono',
                      style: TextStyle(
                          color: Color(0xFF1C1C1E), fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    style: const TextStyle(color: Color(0xFF1C1C1E)),
                    onChanged: (v) => setS(() => consulta = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar (ej. "ropa", "reloj", "tienda")',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: resultados.isEmpty
                        ? const Center(
                            child: Text('Sin resultados', style: TextStyle(color: Color(0xFF8E8E93))))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: resultados.length,
                            itemBuilder: (_, i) {
                              final item = resultados[i];
                              final seleccionado = item.nombre == actual;
                              return GestureDetector(
                                onTap: () => Navigator.pop(ctx, item.nombre),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: seleccionado
                                        ? context.colorPrimario
                                        : const Color(0xFFF2F2F7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.icono,
                                      color: seleccionado ? Colors.white : const Color(0xFF6E6E73),
                                      size: 22),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarDialogoCategoria({CategoriaProducto? existente}) async {
    final ctrlNombre = TextEditingController(text: existente?.nombre);
    String iconoNombre = existente?.icono ?? 'category';
    String? urlImagenLocal = existente?.imagenUrl;
    bool subiendoImagen = false;
    bool guardandoCategoria = false;
    final claveFormulario = GlobalKey<FormState>();

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(existente == null ? 'Nueva categoría' : 'Editar categoría',
              style: const TextStyle(color: Color(0xFF1C1C1E))),
          content: Form(
            key: claveFormulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: subiendoImagen
                      ? null
                      : () async {
                          final accion = await showModalBottomSheet<String>(
                            context: ctx,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (bctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.emoji_symbols_outlined),
                                    title: const Text('Elegir icono'),
                                    onTap: () => Navigator.pop(bctx, 'icono'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.add_photo_alternate_outlined),
                                    title: const Text('Subir imagen'),
                                    onTap: () => Navigator.pop(bctx, 'imagen'),
                                  ),
                                  if (urlImagenLocal != null)
                                    ListTile(
                                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                                      title: const Text('Quitar imagen',
                                          style: TextStyle(color: Colors.red)),
                                      onTap: () => Navigator.pop(bctx, 'quitar'),
                                    ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          );
                          if (accion == 'icono') {
                            final elegido = await _elegirIcono(iconoNombre);
                            if (elegido != null) setLocal(() => iconoNombre = elegido);
                          } else if (accion == 'imagen') {
                            setLocal(() => subiendoImagen = true);
                            final url = await ServicioFTP.seleccionarYSubirImagen(
                              nombreArchivo: 'categoria-${ctrlNombre.text.trim()}',
                              onError: (e) {
                                if (ctx.mounted) {
                                  mostrarToast(ctx, e, tipo: TipoToast.error);
                                }
                              },
                            );
                            setLocal(() {
                              subiendoImagen = false;
                              if (url != null) urlImagenLocal = url;
                            });
                          } else if (accion == 'quitar') {
                            setLocal(() => urlImagenLocal = null);
                          }
                        },
                  child: Container(
                    width: 56,
                    height: 56,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        color: context.colorPrimario, shape: BoxShape.circle),
                    child: subiendoImagen
                        ? const Center(
                            child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)))
                        : urlImagenLocal != null
                            ? Image.network(urlImagenLocal!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    obtenerIconoServicio(iconoNombre),
                                    color: Colors.white, size: 26))
                            : Icon(obtenerIconoServicio(iconoNombre),
                                color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ctrlNombre,
                  autofocus: true,
                  maxLength: 40,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la categoría',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.colorPrimario),
              onPressed: guardandoCategoria
                  ? null
                  : () async {
                if (!claveFormulario.currentState!.validate()) return;
                setLocal(() => guardandoCategoria = true);
                final prov = context.read<ProveedorCategoriasProducto>();
                final ok = existente == null
                    ? await prov.crearCategoria(
                        nombre: ctrlNombre.text.trim(),
                        icono: iconoNombre,
                        imagenUrl: urlImagenLocal)
                    : await prov.actualizarCategoria(existente.id,
                        nombre: ctrlNombre.text.trim(),
                        icono: iconoNombre,
                        imagenUrl: urlImagenLocal);
                if (ctx.mounted) Navigator.pop(ctx, ok);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (exito == true && mounted) {
      mostrarToast(context, 'Categoría guardada', tipo: TipoToast.exito);
    }
  }

  Future<void> _confirmarEliminar(CategoriaProducto categoria) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar categoría', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: Text(
            '¿Eliminar "${categoria.nombre}"? Los productos asignados quedarán sin categoría.',
            style: const TextStyle(color: Color(0xFF6E6E73))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ProveedorCategoriasProducto>().eliminarCategoria(categoria.id);
    }
  }

  void _gestionarProductos(CategoriaProducto categoria) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PaginaProductosDeCategoria(categoria: categoria),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final categorias = context.watch<ProveedorCategoriasProducto>().categorias;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Categorías de productos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoCategoria(),
        backgroundColor: context.colorPrimario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: EnvolturaResponsiva(
        child: SafeArea(
        child: categorias.isEmpty
            ? const Center(
                child: Text('Sin categorías todavía', style: TextStyle(color: kTextSub)))
            : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                buildDefaultDragHandles: false,
                itemCount: categorias.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final nuevos = List<CategoriaProducto>.from(categorias);
                  final item = nuevos.removeAt(oldIndex);
                  nuevos.insert(newIndex, item);
                  context.read<ProveedorCategoriasProducto>().reordenarCategorias(nuevos);
                },
                itemBuilder: (context, i) {
                  final c = categorias[i];
                  return EntradaAnimada(
                    key: ValueKey(c.id),
                    index: i,
                    child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ReorderableDragStartListener(
                            index: i,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.drag_handle_rounded,
                                      color: Color(0xFF8E8E93)),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: context.colorPrimario,
                                      shape: BoxShape.circle,
                                    ),
                                    child: c.imagenUrl != null
                                        ? Image.network(c.imagenUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                                obtenerIconoServicio(c.icono),
                                                color: Colors.white, size: 18))
                                        : Icon(obtenerIconoServicio(c.icono),
                                            color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(c.nombre,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1C1C1E))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Color(0xFF8E8E93)),
                          onSelected: (accion) {
                            if (accion == 'productos') _gestionarProductos(c);
                            if (accion == 'editar') _mostrarDialogoCategoria(existente: c);
                            if (accion == 'eliminar') _confirmarEliminar(c);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'productos',
                                child: Row(children: [
                                  Icon(Icons.inventory_2_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Productos'),
                                ])),
                            PopupMenuItem(
                                value: 'editar',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ])),
                            PopupMenuItem(
                                value: 'eliminar',
                                child: Row(children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ])),
                          ],
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                    ),
                  );
                },
              ),
      ),
      ),
    );
  }
}

// ── Asignar/quitar productos de una categoría ─────────────────────────────
class _PaginaProductosDeCategoria extends StatefulWidget {
  final CategoriaProducto categoria;
  const _PaginaProductosDeCategoria({required this.categoria});

  @override
  State<_PaginaProductosDeCategoria> createState() =>
      _PaginaProductosDeCategoriaState();
}

class _PaginaProductosDeCategoriaState extends State<_PaginaProductosDeCategoria> {
  late Set<String> _seleccionados;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _seleccionados = context
        .read<ProveedorProducto>()
        .productos
        .where((p) => p.categoriaId == widget.categoria.id)
        .map((p) => p.id)
        .toSet();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final prov = context.read<ProveedorProducto>();
    for (final p in prov.productos) {
      final debeEstar = _seleccionados.contains(p.id);
      final estaba = p.categoriaId == widget.categoria.id;
      if (debeEstar != estaba) {
        await prov.actualizarProducto(
            p.id, {'category_id': debeEstar ? widget.categoria.id : null});
      }
    }
    if (!mounted) return;
    setState(() => _guardando = false);
    mostrarToast(context, 'Productos de "${widget.categoria.nombre}" actualizados',
        tipo: TipoToast.exito);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: Text('Productos en "${widget.categoria.nombre}"')),
      body: EnvolturaResponsiva(
        child: SafeArea(
        child: Consumer<ProveedorProducto>(
          builder: (context, prov, __) {
            final productos = prov.productos;
            if (productos.isEmpty) {
              return const Center(
                  child: Text('No hay productos', style: TextStyle(color: kTextSub)));
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Text('${_seleccionados.length} de ${productos.length} seleccionados',
                          style: const TextStyle(color: kTextSub, fontSize: 13)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: productos.length,
                    itemBuilder: (context, i) {
                      final p = productos[i];
                      final seleccionado = _seleccionados.contains(p.id);
                      return EntradaAnimada(
                        index: i,
                        child: TarjetaPresionable(
                        onTap: () => setState(() {
                          if (seleccionado) {
                            _seleccionados.remove(p.id);
                          } else {
                            _seleccionados.add(p.id);
                          }
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? context.colorPrimario.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: seleccionado
                                  ? context.colorPrimario
                                  : const Color(0xFFE5E5EA),
                              width: seleccionado ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  color: const Color(0xFFF2F2F7),
                                  child: p.urlImagen != null
                                      ? Image.network(p.urlImagen!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                              Icons.inventory_2_outlined,
                                              color: kTextMuted, size: 18))
                                      : const Icon(Icons.inventory_2_outlined,
                                          color: kTextMuted, size: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(p.nombre,
                                    style: TextStyle(
                                        color: const Color(0xFF1C1C1E),
                                        fontSize: 14,
                                        fontWeight:
                                            seleccionado ? FontWeight.w700 : FontWeight.w500)),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: seleccionado ? context.colorPrimario : Colors.transparent,
                                  border: Border.all(
                                    color: seleccionado
                                        ? context.colorPrimario
                                        : const Color(0xFFC7C7CC),
                                    width: 1.5,
                                  ),
                                ),
                                child: seleccionado
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorPrimario,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar cambios',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}
