import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_fonts.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../../data/ftp_upload_service.dart';
import '../../domain/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import '../client/home_page.dart';
import '../common/app_widgets.dart';
import '../common/toast.dart';
import 'section_order_page.dart';
import 'product_categories_page.dart';

class PaginaDisenadorVista extends StatelessWidget {
  const PaginaDisenadorVista({super.key});

  Future<void> _toggleTienda(BuildContext context, bool valor) async {
    final cfg = context.read<ProveedorConfig>();
    final exito = await cfg.actualizarTiendaHabilitada(valor);
    if (context.mounted) {
      mostrarToast(
        context,
        exito
            ? (valor ? 'Tienda en línea activada' : 'Tienda en línea desactivada')
            : 'Error al guardar el cambio',
        tipo: exito ? TipoToast.exito : TipoToast.error,
      );
    }
  }

  Future<void> _toggleReservas(BuildContext context, bool valor) async {
    final cfg = context.read<ProveedorConfig>();
    final exito = await cfg.actualizarReservasHabilitadas(valor);
    if (context.mounted) {
      mostrarToast(
        context,
        exito
            ? (valor ? 'Reservas activadas' : 'Reservas desactivadas')
            : 'Error al guardar el cambio',
        tipo: exito ? TipoToast.exito : TipoToast.error,
      );
    }
  }

  Future<void> _cambiarLogo(BuildContext context) async {
    final url = await ServicioFTP.seleccionarYSubirImagen(
      nombreArchivo: 'logo',
      onError: (e) {
        if (context.mounted) {
          mostrarToast(context, e, tipo: TipoToast.error);
        }
      },
    );
    if (url == null || !context.mounted) return;

    final exito = await context.read<ProveedorConfig>().actualizarLogoUrl(url);
    if (context.mounted) {
      mostrarToast(context, exito ? 'Logo actualizado' : 'Error al guardar el logo',
          tipo: exito ? TipoToast.exito : TipoToast.error);
    }
  }

  Future<void> _toggleEditorVistasAdmin(BuildContext context, bool valor) async {
    final cfg = context.read<ProveedorConfig>();
    final exito = await cfg.actualizarEditorVistasAdmin(valor);
    if (context.mounted) {
      mostrarToast(
        context,
        exito
            ? (valor
                ? 'Admin ahora puede editar la vista'
                : 'Editor de vistas restringido de nuevo a sysadmin')
            : 'Error al guardar el cambio',
        tipo: exito ? TipoToast.exito : TipoToast.error,
      );
    }
  }

  Future<Color?> _elegirColorPersonalizado(BuildContext context, Color actual) async {
    Color temporal = actual;
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Color personalizado', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temporal,
            onColorChanged: (c) => temporal = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, temporal),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorColor(BuildContext context) {
    final config = context.read<ProveedorConfig>();
    const colores = [
      Color(0xFF00BFA5), Color(0xFF007AFF), Color(0xFF5856D6),
      Color(0xFFFF2D55), Color(0xFFFF9500), Color(0xFF34C759),
      Color(0xFFFF3B30), Color(0xFF4ECDC4), Color(0xFF1ABC9C),
      Color(0xFF8E44AD), Color(0xFF2ECC71), Color(0xFFE74C3C),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: kTextMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color de la aplicación',
                style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colores.map((c) {
                final seleccionado = config.colorPrimarioBorrador.value == c.value;
                return GestureDetector(
                  onTap: () {
                    config.actualizarBorradorColor(c);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: seleccionado
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: seleccionado
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)]
                          : null,
                    ),
                    child: seleccionado
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList()
                ..add(
                  GestureDetector(
                    onTap: () async {
                      final elegido =
                          await _elegirColorPersonalizado(context, config.colorPrimarioBorrador);
                      if (elegido != null) {
                        config.actualizarBorradorColor(elegido);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD1D1D6), width: 1.5),
                        gradient: const SweepGradient(colors: [
                          Colors.red, Colors.yellow, Colors.green,
                          Colors.cyan, Colors.blue, Colors.purple, Colors.red,
                        ]),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorColorSecundario(BuildContext context) {
    final config = context.read<ProveedorConfig>();
    const colores = [
      Color(0xFFFFFFFF), Color(0xFFF2F2F7), Color(0xFFFAFAFA),
      Color(0xFF1C1C1E), Color(0xFF000000), Color(0xFFF5F5DC),
      Color(0xFFFFF8E7), Color(0xFFF0F4F8),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: kTextMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color secundario (fondo)',
                style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colores.map((c) {
                final seleccionado = config.colorSecundarioBorrador.value == c.value;
                return GestureDetector(
                  onTap: () {
                    config.actualizarBorradorColorSecundario(c);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: seleccionado ? Colors.transparent : const Color(0xFFE5E5EA),
                          width: seleccionado ? 3 : 1),
                      boxShadow: seleccionado
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)]
                          : null,
                    ),
                    child: seleccionado
                        ? Icon(Icons.check,
                            color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            size: 20)
                        : null,
                  ),
                );
              }).toList()
                ..add(
                  GestureDetector(
                    onTap: () async {
                      final elegido = await _elegirColorPersonalizado(
                          context, config.colorSecundarioBorrador);
                      if (elegido != null) {
                        config.actualizarBorradorColorSecundario(elegido);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD1D1D6), width: 1.5),
                        gradient: const SweepGradient(colors: [
                          Colors.red, Colors.yellow, Colors.green,
                          Colors.cyan, Colors.blue, Colors.purple, Colors.red,
                        ]),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarEstiloApp(BuildContext context) async {
    final cfg = context.read<ProveedorConfig>();
    String fuenteLocal = cfg.fontFamilyBorrador;
    double radioLocal = cfg.radioContenedorBorrador;
    double sombraLocal = cfg.sombraContenedorBorrador;

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
                  const Text('Tipografía y estilo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 16),
                const Text('Fuente', style: TextStyle(
                    fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kFuentesApp.map((f) {
                    final seleccionado = f == fuenteLocal;
                    return GestureDetector(
                      onTap: () => setS(() => fuenteLocal = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: seleccionado
                              ? context.colorPrimario.withOpacity(0.12)
                              : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: seleccionado ? context.colorPrimario : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.getFont(
                            f,
                            textStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: seleccionado ? context.colorPrimario : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Redondez de esquinas: ${radioLocal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                Slider(
                  value: radioLocal,
                  min: 0,
                  max: 28,
                  divisions: 14,
                  activeColor: context.colorPrimario,
                  onChanged: (v) => setS(() => radioLocal = v),
                ),
                const SizedBox(height: 8),
                Text('Intensidad de sombra: ${sombraLocal.toStringAsFixed(1)}x',
                    style: const TextStyle(
                        fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                Slider(
                  value: sombraLocal,
                  min: 0,
                  max: 2,
                  divisions: 20,
                  activeColor: context.colorPrimario,
                  onChanged: (v) => setS(() => sombraLocal = v),
                ),
                const SizedBox(height: 12),
                const Text('Vista previa', style: TextStyle(
                    fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(radioLocal),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08 * sombraLocal),
                          blurRadius: 10 * sombraLocal,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.colorPrimario.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.content_cut, color: context.colorPrimario, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Corte de cabello',
                                  style: GoogleFonts.getFont(
                                    fuenteLocal,
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1C1C1E)),
                                  )),
                              const SizedBox(height: 2),
                              Text('Así se verán tus tarjetas',
                                  style: GoogleFonts.getFont(
                                    fuenteLocal,
                                    textStyle: const TextStyle(
                                        fontSize: 12, color: Color(0xFF8E8E93)),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      final exito = await cfg.actualizarBorradorEstilo(
                        fontFamily: fuenteLocal,
                        radioContenedor: radioLocal,
                        sombraContenedor: sombraLocal,
                      );
                      if (context.mounted) {
                        mostrarToast(
                          context,
                          exito ? 'Cambio guardado en el borrador' : 'Error al guardar',
                          tipo: exito ? TipoToast.exito : TipoToast.error,
                        );
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

  Future<void> _editarBanner(BuildContext context) async {
    final cfg = context.read<ProveedorConfig>();
    final imagenesLocal = List<String>.from(cfg.bannerImagenesBorrador);
    final textoCtrl = TextEditingController(text: cfg.bannerTextoBorrador ?? '');
    final botonTextoCtrl = TextEditingController(text: cfg.bannerBotonTextoBorrador ?? '');
    final botonLinkCtrl = TextEditingController(text: cfg.bannerBotonLinkBorrador ?? '');
    String alineacionLocal = cfg.bannerAlineacionBorrador;
    bool subiendoLocal = false;
    const maxImagenes = 5;

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
                  const Text('Editar banner',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: 16),

                // Imágenes (carrusel, hasta 5)
                Text('Imágenes (${imagenesLocal.length}/$maxImagenes)',
                    style: const TextStyle(
                        fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (int i = 0; i < imagenesLocal.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kTextMuted.withOpacity(0.25)),
                                ),
                                child: Image.network(imagenesLocal[i], fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_outlined, color: kTextSub)),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setS(() => imagenesLocal.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                        color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (imagenesLocal.length < maxImagenes)
                        GestureDetector(
                          onTap: subiendoLocal
                              ? null
                              : () async {
                                  setS(() => subiendoLocal = true);
                                  final url = await ServicioFTP.seleccionarYSubirImagen(
                                    nombreArchivo: 'banner-promo-${imagenesLocal.length}',
                                    onError: (e) {
                                      if (context.mounted) {
                                        mostrarToast(context, e, tipo: TipoToast.error);
                                      }
                                    },
                                  );
                                  setS(() {
                                    subiendoLocal = false;
                                    if (url != null) imagenesLocal.add(url);
                                  });
                                },
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kTextMuted.withOpacity(0.25)),
                            ),
                            child: subiendoLocal
                                ? const Center(
                                    child: SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2)))
                                : const Center(
                                    child: Icon(Icons.add_photo_alternate_outlined,
                                        color: kTextSub),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  imagenesLocal.length > 1
                      ? 'Se mostrarán en carrusel automático'
                      : 'Agrega hasta $maxImagenes imágenes para un carrusel',
                  style: const TextStyle(color: kTextSub, fontSize: 11),
                ),
                const SizedBox(height: 12),

                // Texto
                TextField(
                  controller: textoCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Texto del banner',
                    hintText: '¡TU MEJOR LOOK,\nUN TAP DE DISTANCIA!',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Alineación
                const Text('Posición del texto', style: TextStyle(
                    fontSize: 13, color: kTextSub, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _BotonAlineacion(
                      icono: Icons.format_align_left,
                      etiqueta: 'Izquierda',
                      seleccionado: alineacionLocal == 'left',
                      onTap: () => setS(() => alineacionLocal = 'left'),
                    ),
                    const SizedBox(width: 8),
                    _BotonAlineacion(
                      icono: Icons.format_align_center,
                      etiqueta: 'Centro',
                      seleccionado: alineacionLocal == 'center',
                      onTap: () => setS(() => alineacionLocal = 'center'),
                    ),
                    const SizedBox(width: 8),
                    _BotonAlineacion(
                      icono: Icons.format_align_right,
                      etiqueta: 'Derecha',
                      seleccionado: alineacionLocal == 'right',
                      onTap: () => setS(() => alineacionLocal = 'right'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botón
                TextField(
                  controller: botonTextoCtrl,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  decoration: InputDecoration(
                    labelText: 'Texto del botón',
                    hintText: 'Reservar ahora',
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: botonLinkCtrl,
                  style: const TextStyle(color: Color(0xFF1C1C1E)),
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Link del botón (opcional)',
                    hintText: 'https://...',
                    helperText: 'Si lo dejas vacío, el botón lleva a hacer una reserva',
                    helperMaxLines: 2,
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
                      final exito = await cfg.actualizarBorradorBanner(
                            imagenes: imagenesLocal,
                            texto: textoCtrl.text.trim().isEmpty ? null : textoCtrl.text.trim(),
                            alineacion: alineacionLocal,
                            botonTexto: botonTextoCtrl.text.trim().isEmpty
                                ? null : botonTextoCtrl.text.trim(),
                            botonLink: botonLinkCtrl.text.trim().isEmpty
                                ? null : botonLinkCtrl.text.trim(),
                          );
                      if (context.mounted) {
                        mostrarToast(
                          context,
                          exito ? 'Cambio guardado en el borrador' : 'Error al guardar el banner',
                          tipo: exito ? TipoToast.exito : TipoToast.error,
                        );
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

  Future<void> _publicar(BuildContext context) async {
    final cfg = context.read<ProveedorConfig>();
    final exito = await cfg.publicarBorrador();
    if (context.mounted) {
      mostrarToast(context, exito ? 'Cambios publicados' : 'Error al publicar',
          tipo: exito ? TipoToast.exito : TipoToast.error);
    }
  }

  Future<void> _descartar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Descartar cambios', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: const Text('Se perderán todos los cambios sin publicar. ¿Continuar?',
            style: TextStyle(color: Color(0xFF1C1C1E))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    final exito = await context.read<ProveedorConfig>().descartarBorrador();
    if (context.mounted) {
      mostrarToast(context, exito ? 'Cambios descartados' : 'Error al descartar',
          tipo: exito ? TipoToast.exito : TipoToast.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.watch<ProveedorConfig>();
    final tiendaHabilitada = cfg.tiendaHabilitada;
    final reservasHabilitadas = cfg.reservasHabilitadas;
    final editorVistasAdmin = cfg.editorVistasAdmin;
    final esSysadmin = context.watch<ProveedorAuth>().perfil?.rol == RolUsuario.sysadmin;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Diseñador de vista')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (cfg.tieneBorrador) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colorPrimario.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colorPrimario.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, color: context.colorPrimario, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Tienes cambios sin publicar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1C1C1E))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Los clientes reales siguen viendo la versión publicada. Usa "Editar vista" '
                      'para previsualizar tus cambios antes de publicarlos.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _descartar(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Descartar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _publicar(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colorPrimario,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Publicar cambios',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Text('Identidad del negocio',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text(
              'El logo se usa en el login, el splash y los encabezados de toda la app.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),
            EntradaAnimada(
              index: 0,
              child: TarjetaSeccion(
                child: Row(
                  children: [
                    ClipOval(
                      child: cfg.logoUrl != null && cfg.logoUrl!.isNotEmpty
                          ? Image.network(cfg.logoUrl!, width: 56, height: 56, fit: BoxFit.cover)
                          : Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFFF2F2F7),
                              child: const Icon(Icons.storefront_outlined, color: Color(0xFF8E8E93)),
                            ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text('Logo del negocio',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1C1C1E))),
                    ),
                    TextButton(
                      onPressed: () => _cambiarLogo(context),
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Módulos de la app',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text(
              'Activa o desactiva funciones completas de la app para todos los perfiles.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),
            EntradaAnimada(
              index: 1,
              child: TarjetaSeccion(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colorPrimario.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.storefront_outlined, color: context.colorPrimario),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tienda en línea',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1C1C1E))),
                          const SizedBox(height: 2),
                          Text(
                            tiendaHabilitada
                                ? 'Productos, carrito y pedidos visibles en toda la app'
                                : 'Productos, carrito y pedidos ocultos en toda la app',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: tiendaHabilitada,
                      activeColor: context.colorPrimario,
                      onChanged: (v) => _toggleTienda(context, v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!tiendaHabilitada)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'La tienda está desactivada: clientes, empleados, admins y sysadmin '
                        'no verán productos, buscador, carrito ni pedidos.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TarjetaSeccion(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colorPrimario.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_today_outlined, color: context.colorPrimario),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reservas',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1C1C1E))),
                        const SizedBox(height: 2),
                        Text(
                          reservasHabilitadas
                              ? 'Agendar citas visible en toda la app'
                              : 'Agendar citas oculto en toda la app',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: reservasHabilitadas,
                    activeColor: context.colorPrimario,
                    onChanged: (v) => _toggleReservas(context, v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!reservasHabilitadas)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Las reservas están desactivadas: clientes, empleados y admins '
                        'no verán la pestaña de reservas ni el aviso de "Reservar ahora".',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ],
                ),
              ),
            if (esSysadmin) ...[
              const SizedBox(height: 12),
              EntradaAnimada(
                index: 2,
                child: TarjetaSeccion(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colorPrimario.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.dashboard_customize_outlined, color: context.colorPrimario),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Editor de vistas para admin',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            const SizedBox(height: 2),
                            Text(
                              editorVistasAdmin
                                  ? 'El rol admin también ve la pestaña "Vista"'
                                  : 'Solo sysadmin ve la pestaña "Vista" (como hasta ahora)',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: editorVistasAdmin,
                        activeColor: context.colorPrimario,
                        onChanged: (v) => _toggleEditorVistasAdmin(context, v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Color de la aplicación',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text(
              'El color principal usado en botones, íconos y acentos de toda la app.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _mostrarSelectorColor(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cfg.colorPrimarioBorrador,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cfg.colorPrimarioBorrador.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Color primario',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            SizedBox(height: 2),
                            Text('Toca para elegir un color',
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color secundario',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text(
              'El fondo de toda la app, incluyendo la pantalla de inicio de sesión.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _mostrarSelectorColorSecundario(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cfg.colorSecundarioBorrador,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Color secundario (fondo)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            SizedBox(height: 2),
                            Text('Toca para elegir un color',
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Tipografía y estilo',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text(
              'Fuente, redondez y sombra de las tarjetas en toda la app.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _editarEstiloApp(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colorPrimario.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.text_fields_rounded, color: context.colorPrimario),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cfg.fontFamilyBorrador,
                                style: GoogleFonts.getFont(
                                  cfg.fontFamilyBorrador,
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1C1C1E)),
                                )),
                            const SizedBox(height: 2),
                            const Text('Editar fuente, redondez y sombra',
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Personalizar secciones',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E))),
            const SizedBox(height: 4),
            const Text(
              'Inspecciona la tienda tal como la ve el cliente y edita sus secciones.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Editar vista'),
                      actions: [
                        Consumer<ProveedorConfig>(
                          builder: (ctx, previewCfg, __) => previewCfg.tieneBorrador
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: TextButton.icon(
                                    onPressed: () => _publicar(ctx),
                                    icon: Icon(Icons.cloud_upload_outlined,
                                        size: 18, color: ctx.colorPrimario),
                                    label: Text('Publicar',
                                        style: TextStyle(
                                            color: ctx.colorPrimario,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    body: const PaginaInicio(modoEdicion: true),
                  ),
                )),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colorPrimario.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit_note_outlined, color: context.colorPrimario),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Editar vista',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            SizedBox(height: 2),
                            Text('Inspecciona y edita la vista del cliente',
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PaginaOrdenSecciones(),
                )),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colorPrimario.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.reorder_rounded, color: context.colorPrimario),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Orden de secciones',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            SizedBox(height: 2),
                            Text('Reordena y muestra/oculta secciones del home',
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PaginaCategoriasProducto(),
                )),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colorPrimario.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.category_outlined, color: context.colorPrimario),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Categorías de productos',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            SizedBox(height: 2),
                            Text('Crea, edita y asigna productos a categorías',
                                style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: Color(0xFF8E8E93)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<ProveedorConfig>(
              builder: (_, bannerCfg, __) => Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _editarBanner(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: context.colorPrimario.withOpacity(0.1),
                            child: bannerCfg.bannerImagenesBorrador.isNotEmpty
                                ? Image.network(bannerCfg.bannerImagenesBorrador.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.image_outlined, color: context.colorPrimario))
                                : Icon(Icons.image_outlined, color: context.colorPrimario),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Banner promocional',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1C1C1E))),
                              const SizedBox(height: 2),
                              Text(
                                bannerCfg.bannerImagenesBorrador.length > 1
                                    ? '${bannerCfg.bannerImagenesBorrador.length} imágenes en carrusel'
                                    : 'Imagen, texto y posición del banner del home',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Color(0xFF8E8E93)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón de selección de alineación del banner ──────────────
class _BotonAlineacion extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _BotonAlineacion({
    required this.icono,
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return Expanded(
      child: GestureDetector(
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
                      fontSize: 10,
                      color: seleccionado ? color : kTextSub,
                      fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
