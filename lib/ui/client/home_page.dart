import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/product_provider.dart';
import '../../domain/models/service_model.dart' show ModeloServicio;
import '../../domain/models/product.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/service_icons.dart';
import '../../core/cart_fly_animation.dart';
import '../../core/entrada_animada.dart';
import '../../providers/cart_provider.dart';
import '../../providers/saved_provider.dart';
import '../../providers/config_provider.dart';
import '../cart/cart_page.dart';
import '../common/app_widgets.dart';
import '../auth/guest_wall_page.dart';

class PaginaInicio extends StatefulWidget {
  final bool modoEdicion;
  const PaginaInicio({super.key, this.modoEdicion = false});

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  final _ctrlBusqueda = TextEditingController();
  final _carritoKey = GlobalKey();
  String _busqueda = '';
  ProveedorConfig? _cfgVistaPrevia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorServicio>().cargarServicios();
      if (context.read<ProveedorConfig>().tiendaHabilitada) {
        context.read<ProveedorProducto>().cargarProductos(esVistaAdmin: false);
      }
      if (widget.modoEdicion) {
        _cfgVistaPrevia = context.read<ProveedorConfig>();
        _cfgVistaPrevia!.activarVistaPrevia();
      }
    });
  }

  @override
  void dispose() {
    _ctrlBusqueda.dispose();
    _cfgVistaPrevia?.desactivarVistaPrevia();
    super.dispose();
  }

  Future<void> _editarSeccionCategorias() async {
    final cfg = context.read<ProveedorConfig>();
    final ctrlTitulo = TextEditingController(text: cfg.categoriasTituloBorrador);
    String formaLocal = cfg.categoriasFormaBorrador;
    double tamanoIconoLocal = cfg.categoriasIconoTamanoBorrador;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Editar sección',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrlTitulo,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Título de la sección',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Forma de los íconos', style: TextStyle(
                    fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _BotonForma(
                        icono: Icons.circle_outlined,
                        etiqueta: 'Círculo',
                        seleccionado: formaLocal == 'circulo',
                        onTap: () => setS(() => formaLocal = 'circulo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BotonForma(
                        icono: Icons.square_outlined,
                        etiqueta: 'Cuadrado',
                        seleccionado: formaLocal == 'cuadrado',
                        onTap: () => setS(() => formaLocal = 'cuadrado'),
                      ),
                    ),
                  ],
                ),
                if (formaLocal == 'cuadrado') ...[
                  const SizedBox(height: 20),
                  Text('Tamaño de íconos: ${tamanoIconoLocal.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                  Slider(
                    value: tamanoIconoLocal,
                    min: 16,
                    max: 36,
                    divisions: 10,
                    activeColor: context.colorPrimario,
                    onChanged: (v) => setS(() => tamanoIconoLocal = v),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorPrimario,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final exito = await cfg.actualizarBorradorCategorias(
                        titulo: ctrlTitulo.text.trim().isEmpty
                            ? 'Categorías de Servicios'
                            : ctrlTitulo.text.trim(),
                        forma: formaLocal,
                        tamanoIcono: tamanoIconoLocal,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(exito ? 'Cambio guardado en el borrador' : 'Error al guardar'),
                          backgroundColor: exito ? Colors.green : Colors.red,
                        ));
                      }
                    },
                    child: const Text('Guardar cambios',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editarTituloProductos() async {
    final cfg = context.read<ProveedorConfig>();
    final ctrlTitulo = TextEditingController(text: cfg.productosTituloBorrador);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Editar sección',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: ctrlTitulo,
                style: const TextStyle(color: Color(0xFF1C1C1E)),
                decoration: InputDecoration(
                  labelText: 'Título de la sección',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorPrimario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final exito = await cfg.actualizarBorradorProductos(
                      ctrlTitulo.text.trim().isEmpty
                          ? 'Productos Populares'
                          : ctrlTitulo.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(exito ? 'Cambio guardado en el borrador' : 'Error al guardar'),
                        backgroundColor: exito ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  child: const Text('Guardar cambios',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _slivsCategorias({
    required ProveedorServicio provServicio,
    required ProveedorConfig provConfig,
    required List<ModeloServicio> servicios,
  }) {
    return [
      // ── Categorías de servicios — título ─────────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  provConfig.categoriasTituloEfectivo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              if (widget.modoEdicion)
                GestureDetector(
                  onTap: _editarSeccionCategorias,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: context.colorPrimario.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_outlined,
                        size: 16, color: context.colorPrimario),
                  ),
                ),
              if (!widget.modoEdicion && servicios.isNotEmpty)
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

      // ── Chips de servicios (circulares u horizontales) ───
      if (provServicio.cargando)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      else if (servicios.isNotEmpty && provConfig.categoriasFormaEfectiva == 'cuadrado')
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => EntradaAnimada(
                index: i,
                child: _ChipServicioCuadrado(
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
              childCount: servicios.length,
            ),
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
              itemBuilder: (context, i) => EntradaAnimada(
                index: i,
                child: _ChipServicio(
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
        ),
    ];
  }

  List<Widget> _slivsProductos({
    required ProveedorConfig provConfig,
    required List<Producto> todosProductos,
    required List<Producto> productos,
  }) {
    return [
      // ── Productos populares — título ──────────────────────
      if (todosProductos.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _busqueda.isEmpty ? provConfig.productosTituloEfectivo : 'Resultados',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                if (widget.modoEdicion)
                  GestureDetector(
                    onTap: _editarTituloProductos,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: context.colorPrimario.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_outlined,
                          size: 16, color: context.colorPrimario),
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

      // ── Grid de productos (columnas según ancho de pantalla) ─
      if (productos.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => EntradaAnimada(
                index: i,
                child: _TarjetaProductoH(producto: productos[i], carritoKey: _carritoKey),
              ),
              childCount: productos.length,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;
    final provServicio = context.watch<ProveedorServicio>();
    final provProducto = context.watch<ProveedorProducto>();
    final provConfig = context.watch<ProveedorConfig>();
    final tiendaHabilitada = provConfig.tiendaHabilitada;
    final servicios = provServicio.servicios;
    final todosProductos = tiendaHabilitada ? provProducto.productos : <Producto>[];
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
                  if (perfil != null) ...[
                    const IconoNotificaciones(),
                    const SizedBox(width: 12),
                  ],
                  if (tiendaHabilitada) ...[
                    _IconoCarrito(key: _carritoKey),
                    const SizedBox(width: 12),
                  ],
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(kUrlLogoBarberia),
                  ),
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
            if (tiendaHabilitada)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
              child: Builder(builder: (context) {
                final seccionesDisponibles = <String, List<Widget>>{
                  'categorias': _slivsCategorias(
                    provServicio: provServicio,
                    provConfig: provConfig,
                    servicios: servicios,
                  ),
                  'banner_promo': const [SliverToBoxAdapter(child: _BannerPromo())],
                  'productos': _slivsProductos(
                    provConfig: provConfig,
                    todosProductos: todosProductos,
                    productos: productos,
                  ),
                };

                return CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // ── Banner hero (fijo, de referencia — nunca se toca) ─
                    const SliverToBoxAdapter(child: _BannerReferencia()),

                    for (final s in provConfig.seccionesHomeEfectivas)
                      if (s['visible'] == true && seccionesDisponibles.containsKey(s['key']))
                        ...seccionesDisponibles[s['key']]!,

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner hero fijo (solo de referencia — nunca lo toca sysadmin) ─
class _BannerReferencia extends StatelessWidget {
  const _BannerReferencia();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  child: const Icon(Icons.content_cut, color: Colors.white, size: 32),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
    );
  }
}

// ── Banner promocional dinámico (imagen configurable desde sysadmin,
// no se muestra nada si no hay imagen) ──────────────────────────
class _BannerPromo extends StatelessWidget {
  const _BannerPromo();

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ProveedorConfig>();
    final bannerUrl = cfg.bannerUrlEfectivo;
    if (bannerUrl == null || bannerUrl.isEmpty) return const SizedBox.shrink();

    final tieneTexto = cfg.bannerTextoEfectivo != null && cfg.bannerTextoEfectivo!.trim().isNotEmpty;
    final texto = cfg.bannerTextoEfectivo ?? '';
    final botonTexto =
        (cfg.bannerBotonTextoEfectivo != null && cfg.bannerBotonTextoEfectivo!.trim().isNotEmpty)
            ? cfg.bannerBotonTextoEfectivo!
            : 'Reservar ahora';
    final botonLink = cfg.bannerBotonLinkEfectivo;
    final (crossAlign, boxAlign) = switch (cfg.bannerAlineacionEfectiva) {
      'center' => (CrossAxisAlignment.center, Alignment.center),
      'right' => (CrossAxisAlignment.end, Alignment.centerRight),
      _ => (CrossAxisAlignment.start, Alignment.centerLeft),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: !tieneTexto
            ? null
            : () async {
                if (botonLink != null && botonLink.trim().isNotEmpty) {
                  final uri = Uri.tryParse(botonLink.trim());
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  return;
                }
                if (context.read<ProveedorAuth>().perfil == null) {
                  mostrarLoginRequerido(context);
                  return;
                }
                if (context.mounted) context.push('/booking/service');
              },
        child: Container(
          height: 130,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
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
              Positioned.fill(
                child: Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              if (tieneTexto)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.45), Colors.black.withOpacity(0.15)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              if (tieneTexto)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: boxAlign,
                    child: Column(
                      crossAxisAlignment: crossAlign,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          texto,
                          textAlign: switch (cfg.bannerAlineacionEfectiva) {
                            'center' => TextAlign.center,
                            'right' => TextAlign.right,
                            _ => TextAlign.left,
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            botonTexto,
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
                ),
            ],
          ),
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
    const tamanoIcono = 22.0;
    return GestureDetector(
      onTap: alTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorDesdeHex(servicio.iconoColor) ?? kCard,
              shape: BoxShape.circle,
              boxShadow: kNeumorphicShadowsSmall,
            ),
            child: Icon(obtenerIconoServicio(servicio.iconoNombre), color: Colors.white, size: tamanoIcono),
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

// ── Tile cuadrado de servicio (ancho completo, responsivo) ────
class _ChipServicioCuadrado extends StatelessWidget {
  final ModeloServicio servicio;
  final VoidCallback alTap;
  const _ChipServicioCuadrado({required this.servicio, required this.alTap});

  @override
  Widget build(BuildContext context) {
    final color = colorDesdeHex(servicio.iconoColor) ?? context.colorPrimario;
    final tamanoIcono = context.watch<ProveedorConfig>().categoriasIconoTamanoEfectivo + 6;
    return GestureDetector(
      onTap: alTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kNeumorphicShadowsSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(obtenerIconoServicio(servicio.iconoNombre), color: Colors.white, size: tamanoIcono),
            const SizedBox(height: 10),
            Text(
              servicio.nombre,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de producto horizontal (tarjeta oscura) ───────────
class _TarjetaProductoH extends StatelessWidget {
  final Producto producto;
  final GlobalKey? carritoKey;
  const _TarjetaProductoH({required this.producto, this.carritoKey});

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
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C1E),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Stock + precio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
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
                      ]),
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
                          Text(
                            tieneOferta ? precioOferta! : precio,
                            style: TextStyle(
                                color: tieneOferta
                                    ? const Color(0xFF1C8A4A)
                                    : const Color(0xFF1C1C1E),
                                fontSize: 14,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // ── Botones ───────────────────────────────
                  Row(children: [
                    Expanded(
                      child: Consumer<ProveedorGuardados>(
                        builder: (ctx, guardados, _) => _BotonTarjetaH(
                          label: 'Al carrito',
                          onTap: sinStock
                              ? null
                              : () {
                                  AnimacionCarrito.volar(
                                    contextOrigen: context,
                                    destinoKey: carritoKey,
                                    imagenUrl: producto.urlImagen,
                                  );
                                  context.read<ProveedorCarrito>().agregar(producto);
                                },
                          outlined: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _BotonTarjetaH(
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
          child: Icon(Icons.inventory_2_outlined,
              size: 28, color: kTextMuted),
        ),
      );
}

// ── Botón de tarjeta producto ─────────────────────────────────
class _BotonTarjetaH extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  const _BotonTarjetaH({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1C1C1E);
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
              child: Icon(Icons.shopping_cart_outlined,
                  size: 18,
                  color: onTap == null ? Colors.black26 : bg),
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
  const _IconoCarrito({super.key});

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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: kNeumorphicShadowsSmall,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 20, color: Color(0xFF6E6E73)),
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

// ── Botón de selección de forma (círculo/cuadrado) ────────────
class _BotonForma extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonForma({
    required this.icono,
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.12) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: seleccionado ? color : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icono, size: 18, color: seleccionado ? color : kTextSub),
            const SizedBox(height: 4),
            Text(etiqueta,
                style: TextStyle(
                    fontSize: 12,
                    color: seleccionado ? color : kTextSub,
                    fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
