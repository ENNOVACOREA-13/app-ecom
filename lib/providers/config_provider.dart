import 'package:flutter/material.dart';
import '../data/config_repository.dart';
import '../core/theme/app_theme.dart';
import '../core/service_icons.dart';

class ProveedorConfig extends ChangeNotifier {
  final _repo = RepositorioConfig();

  // ── Valores publicados (en vivo) ──────────────────────────────
  Color _colorPrimario = kPrimary;
  String? _bannerUrl;
  String? _bannerTexto;
  String _bannerAlineacion = 'left';
  String? _bannerBotonTexto;
  String? _bannerBotonLink;
  bool _tiendaHabilitada = true;
  String _categoriasTitulo = 'Categorías de Servicios';
  String _categoriasForma = 'circulo';
  double _categoriasIconoTamano = 22;
  String _fontFamily = 'Poppins';
  double _radioContenedor = 16;
  double _sombraContenedor = 1;
  String _productosTitulo = 'Productos Populares';
  List<Map<String, dynamic>> _seccionesHome =
      List<Map<String, dynamic>>.from(kSeccionesHomePorDefecto);

  // ── Borrador (cambios sin publicar) ───────────────────────────
  bool _tieneBorrador = false;
  bool _modoVistaPrevia = false;
  Color _draftColorPrimario = kPrimary;
  String? _draftBannerUrl;
  String? _draftBannerTexto;
  String _draftBannerAlineacion = 'left';
  String? _draftBannerBotonTexto;
  String? _draftBannerBotonLink;
  String _draftCategoriasTitulo = 'Categorías de Servicios';
  String _draftCategoriasForma = 'circulo';
  double _draftCategoriasIconoTamano = 22;
  String _draftFontFamily = 'Poppins';
  double _draftRadioContenedor = 16;
  double _draftSombraContenedor = 1;
  String _draftProductosTitulo = 'Productos Populares';
  List<Map<String, dynamic>> _draftSeccionesHome =
      List<Map<String, dynamic>>.from(kSeccionesHomePorDefecto);

  // ── Getters: en vivo ───────────────────────────────────────────
  Color get colorPrimario => _colorPrimario;
  String? get bannerUrl => _bannerUrl;
  String? get bannerTexto => _bannerTexto;
  String get bannerAlineacion => _bannerAlineacion;
  String? get bannerBotonTexto => _bannerBotonTexto;
  String? get bannerBotonLink => _bannerBotonLink;
  bool get tiendaHabilitada => _tiendaHabilitada;
  String get categoriasTitulo => _categoriasTitulo;
  String get categoriasForma => _categoriasForma;
  double get categoriasIconoTamano => _categoriasIconoTamano;
  String get fontFamily => _fontFamily;
  double get radioContenedor => _radioContenedor;
  double get sombraContenedor => _sombraContenedor;
  String get productosTitulo => _productosTitulo;
  List<Map<String, dynamic>> get seccionesHome => List.unmodifiable(_seccionesHome);

  // ── Getters: borrador ────────────────────────────────────────
  bool get tieneBorrador => _tieneBorrador;
  bool get modoVistaPrevia => _modoVistaPrevia;
  Color get colorPrimarioBorrador => _draftColorPrimario;
  String? get bannerUrlBorrador => _draftBannerUrl;
  String? get bannerTextoBorrador => _draftBannerTexto;
  String get bannerAlineacionBorrador => _draftBannerAlineacion;
  String? get bannerBotonTextoBorrador => _draftBannerBotonTexto;
  String? get bannerBotonLinkBorrador => _draftBannerBotonLink;
  String get categoriasTituloBorrador => _draftCategoriasTitulo;
  String get categoriasFormaBorrador => _draftCategoriasForma;
  double get categoriasIconoTamanoBorrador => _draftCategoriasIconoTamano;
  String get fontFamilyBorrador => _draftFontFamily;
  double get radioContenedorBorrador => _draftRadioContenedor;
  double get sombraContenedorBorrador => _draftSombraContenedor;
  String get productosTituloBorrador => _draftProductosTitulo;
  List<Map<String, dynamic>> get seccionesHomeBorrador => List.unmodifiable(_draftSeccionesHome);

  // ── Getters "efectivos": borrador si hay vista previa activa, si no en vivo ─
  Color get colorPrimarioEfectivo => _modoVistaPrevia ? _draftColorPrimario : _colorPrimario;
  String? get bannerUrlEfectivo => _modoVistaPrevia ? _draftBannerUrl : _bannerUrl;
  String? get bannerTextoEfectivo => _modoVistaPrevia ? _draftBannerTexto : _bannerTexto;
  String get bannerAlineacionEfectiva =>
      _modoVistaPrevia ? _draftBannerAlineacion : _bannerAlineacion;
  String? get bannerBotonTextoEfectivo =>
      _modoVistaPrevia ? _draftBannerBotonTexto : _bannerBotonTexto;
  String? get bannerBotonLinkEfectivo =>
      _modoVistaPrevia ? _draftBannerBotonLink : _bannerBotonLink;
  String get categoriasTituloEfectivo =>
      _modoVistaPrevia ? _draftCategoriasTitulo : _categoriasTitulo;
  String get categoriasFormaEfectiva =>
      _modoVistaPrevia ? _draftCategoriasForma : _categoriasForma;
  double get categoriasIconoTamanoEfectivo =>
      _modoVistaPrevia ? _draftCategoriasIconoTamano : _categoriasIconoTamano;
  String get fontFamilyEfectiva => _modoVistaPrevia ? _draftFontFamily : _fontFamily;
  double get radioContenedorEfectivo =>
      _modoVistaPrevia ? _draftRadioContenedor : _radioContenedor;
  double get sombraContenedorEfectiva =>
      _modoVistaPrevia ? _draftSombraContenedor : _sombraContenedor;
  String get productosTituloEfectivo =>
      _modoVistaPrevia ? _draftProductosTitulo : _productosTitulo;
  List<Map<String, dynamic>> get seccionesHomeEfectivas =>
      _modoVistaPrevia ? seccionesHomeBorrador : seccionesHome;

  void activarVistaPrevia() {
    _modoVistaPrevia = true;
    notifyListeners();
  }

  void desactivarVistaPrevia() {
    _modoVistaPrevia = false;
    notifyListeners();
  }

  Future<void> cargar() async {
    final color = await _repo.obtenerColorPrimario();
    final banner = await _repo.obtenerBannerConfig();
    final tienda = await _repo.obtenerTiendaHabilitada();
    final categorias = await _repo.obtenerSeccionCategorias();
    final estilo = await _repo.obtenerEstiloApp();
    final productosTitulo = await _repo.obtenerTituloProductos();
    final secciones = await _repo.obtenerSeccionesHome();
    final borrador = await _repo.obtenerBorrador();

    if (color != null) _colorPrimario = color;
    _bannerUrl = banner.url;
    _bannerTexto = banner.texto;
    _bannerAlineacion = banner.alineacion;
    _bannerBotonTexto = banner.botonTexto;
    _bannerBotonLink = banner.botonLink;
    _tiendaHabilitada = tienda;
    _categoriasTitulo = categorias.titulo;
    _categoriasForma = categorias.forma;
    _categoriasIconoTamano = categorias.tamanoIcono;
    _fontFamily = estilo.fontFamily;
    _radioContenedor = estilo.radioContenedor;
    _sombraContenedor = estilo.sombraContenedor;
    _productosTitulo = productosTitulo;
    _seccionesHome = secciones;

    if (borrador != null) {
      _tieneBorrador = true;
      _draftColorPrimario = colorDesdeHex(borrador['primary_color'] as String?) ?? _colorPrimario;
      _draftBannerUrl = borrador['banner_image_url'] as String?;
      _draftBannerTexto = borrador['banner_text'] as String?;
      _draftBannerAlineacion = borrador['banner_align'] as String? ?? _bannerAlineacion;
      _draftBannerBotonTexto = borrador['banner_button_text'] as String?;
      _draftBannerBotonLink = borrador['banner_button_link'] as String?;
      _draftCategoriasTitulo = borrador['home_categorias_titulo'] as String? ?? _categoriasTitulo;
      _draftCategoriasForma = borrador['home_categorias_forma'] as String? ?? _categoriasForma;
      _draftCategoriasIconoTamano =
          (borrador['categorias_icono_tamano'] as num?)?.toDouble() ?? _categoriasIconoTamano;
      _draftFontFamily = borrador['font_family'] as String? ?? _fontFamily;
      _draftRadioContenedor = (borrador['container_radius'] as num?)?.toDouble() ?? _radioContenedor;
      _draftSombraContenedor = (borrador['container_shadow'] as num?)?.toDouble() ?? _sombraContenedor;
      _draftProductosTitulo = borrador['home_productos_titulo'] as String? ?? _productosTitulo;
      final draftSecciones = borrador['home_sections'] as List?;
      _draftSeccionesHome =
          draftSecciones != null ? draftSecciones.cast<Map<String, dynamic>>() : _seccionesHome;
    } else {
      _tieneBorrador = false;
      _reiniciarBorradorDesdeVivo();
    }

    notifyListeners();
  }

  void _reiniciarBorradorDesdeVivo() {
    _draftColorPrimario = _colorPrimario;
    _draftBannerUrl = _bannerUrl;
    _draftBannerTexto = _bannerTexto;
    _draftBannerAlineacion = _bannerAlineacion;
    _draftBannerBotonTexto = _bannerBotonTexto;
    _draftBannerBotonLink = _bannerBotonLink;
    _draftCategoriasTitulo = _categoriasTitulo;
    _draftCategoriasForma = _categoriasForma;
    _draftCategoriasIconoTamano = _categoriasIconoTamano;
    _draftFontFamily = _fontFamily;
    _draftRadioContenedor = _radioContenedor;
    _draftSombraContenedor = _sombraContenedor;
    _draftProductosTitulo = _productosTitulo;
    _draftSeccionesHome = List<Map<String, dynamic>>.from(_seccionesHome);
  }

  Map<String, dynamic> _snapshotBorrador() => {
        'primary_color': colorAHex(_draftColorPrimario),
        'banner_image_url': _draftBannerUrl,
        'banner_text': _draftBannerTexto,
        'banner_align': _draftBannerAlineacion,
        'banner_button_text': _draftBannerBotonTexto,
        'banner_button_link': _draftBannerBotonLink,
        'home_categorias_titulo': _draftCategoriasTitulo,
        'home_categorias_forma': _draftCategoriasForma,
        'categorias_icono_tamano': _draftCategoriasIconoTamano,
        'font_family': _draftFontFamily,
        'container_radius': _draftRadioContenedor,
        'container_shadow': _draftSombraContenedor,
        'home_productos_titulo': _draftProductosTitulo,
        'home_sections': _draftSeccionesHome,
      };

  Future<bool> _guardarBorrador() async {
    _tieneBorrador = true;
    notifyListeners();
    return _repo.guardarBorrador(_snapshotBorrador());
  }

  Future<bool> actualizarBorradorColor(Color color) async {
    _draftColorPrimario = color;
    return _guardarBorrador();
  }

  Future<bool> actualizarBorradorBanner({
    required String? url,
    required String? texto,
    required String alineacion,
    required String? botonTexto,
    required String? botonLink,
  }) async {
    _draftBannerUrl = url;
    _draftBannerTexto = texto;
    _draftBannerAlineacion = alineacion;
    _draftBannerBotonTexto = botonTexto;
    _draftBannerBotonLink = botonLink;
    return _guardarBorrador();
  }

  Future<bool> actualizarBorradorCategorias({
    required String titulo,
    required String forma,
    required double tamanoIcono,
  }) async {
    _draftCategoriasTitulo = titulo;
    _draftCategoriasForma = forma;
    _draftCategoriasIconoTamano = tamanoIcono;
    return _guardarBorrador();
  }

  Future<bool> actualizarBorradorEstilo({
    required String fontFamily,
    required double radioContenedor,
    required double sombraContenedor,
  }) async {
    _draftFontFamily = fontFamily;
    _draftRadioContenedor = radioContenedor;
    _draftSombraContenedor = sombraContenedor;
    return _guardarBorrador();
  }

  Future<bool> actualizarBorradorProductos(String titulo) async {
    _draftProductosTitulo = titulo;
    return _guardarBorrador();
  }

  Future<bool> actualizarBorradorSecciones(List<Map<String, dynamic>> secciones) async {
    _draftSeccionesHome = secciones;
    return _guardarBorrador();
  }

  Future<bool> publicarBorrador() async {
    final exito = await _repo.publicarBorrador(_snapshotBorrador());
    if (exito) {
      _colorPrimario = _draftColorPrimario;
      _bannerUrl = _draftBannerUrl;
      _bannerTexto = _draftBannerTexto;
      _bannerAlineacion = _draftBannerAlineacion;
      _bannerBotonTexto = _draftBannerBotonTexto;
      _bannerBotonLink = _draftBannerBotonLink;
      _categoriasTitulo = _draftCategoriasTitulo;
      _categoriasForma = _draftCategoriasForma;
      _categoriasIconoTamano = _draftCategoriasIconoTamano;
      _fontFamily = _draftFontFamily;
      _radioContenedor = _draftRadioContenedor;
      _sombraContenedor = _draftSombraContenedor;
      _productosTitulo = _draftProductosTitulo;
      _seccionesHome = List<Map<String, dynamic>>.from(_draftSeccionesHome);
      _tieneBorrador = false;
      notifyListeners();
    }
    return exito;
  }

  Future<bool> descartarBorrador() async {
    final exito = await _repo.descartarBorrador();
    if (exito) {
      _reiniciarBorradorDesdeVivo();
      _tieneBorrador = false;
      notifyListeners();
    }
    return exito;
  }

  Future<bool> actualizarTiendaHabilitada(bool habilitada) async {
    final exito = await _repo.actualizarTiendaHabilitada(habilitada);
    if (exito) {
      _tiendaHabilitada = habilitada;
      notifyListeners();
    }
    return exito;
  }
}
