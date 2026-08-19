import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/activity_service.dart';

/// Ver construirPayloadProducto() en product_repository.dart — mismo motivo.
Map<String, dynamic> construirPayloadCrearInsumo({
  required String? tenantId,
  required String creadoPor,
  required String nombre,
  String? descripcion,
  required int cantidad,
  required double precio,
  required String unidad,
}) {
  return {
    'name': nombre,
    'description': descripcion,
    'stock': cantidad,
    'price': precio,
    'unit': unidad,
    'status': 'active',
    'created_by': creadoPor,
    'tenant_id': tenantId,
  };
}

class PaginaInsumos extends StatefulWidget {
  const PaginaInsumos({super.key});

  @override
  State<PaginaInsumos> createState() => _PaginaInsumosState();
}

class _PaginaInsumosState extends State<PaginaInsumos> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _insumos = [];
  bool _cargando = true;
  String _busqueda = '';

  double get _totalComprado => _insumos.fold<double>(0, (s, i) {
        final precio = (i['price'] as num?)?.toDouble() ?? 0;
        final cantidad = (i['stock'] as num?)?.toDouble() ?? 0;
        return s + (precio * cantidad);
      });

  @override
  void initState() {
    super.initState();
    _cargar();
    ServicioActividad.instancia.registrarPantalla('Insumos');
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final datos = await _client
          .from('supplies')
          .select()
          .order('created_at', ascending: false);
      setState(() => _insumos = List<Map<String, dynamic>>.from(datos));
    } catch (_) {} finally {
      setState(() => _cargando = false);
    }
  }

  List<Map<String, dynamic>> get _filtrados {
    if (_busqueda.isEmpty) return _insumos;
    return _insumos.where((i) =>
        (i['name'] as String).toLowerCase().contains(_busqueda.toLowerCase())).toList();
  }

  Future<void> _mostrarFormulario({Map<String, dynamic>? insumo}) async {
    final perfil = context.read<ProveedorAuth>().perfil;
    final nombreCtrl = TextEditingController(text: insumo?['name'] ?? '');
    final descCtrl = TextEditingController(text: insumo?['description'] ?? '');
    final cantidadCtrl = TextEditingController(text: insumo?['stock']?.toString() ?? '');
    final precioCtrl = TextEditingController(text: insumo?['price']?.toString() ?? '');
    final unidadCtrl = TextEditingController(text: insumo?['unit'] ?? 'unidad');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(insumo == null ? 'Registrar compra' : 'Editar compra',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E))),
            if (insumo != null) ...[
              const SizedBox(height: 4),
              Text('Registrado el ${_fmtFecha(insumo['created_at'] as String?)}',
                  style: const TextStyle(color: kTextSub, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            _campo(nombreCtrl, 'Nombre', Icons.inventory_2_outlined),
            const SizedBox(height: 12),
            _campo(descCtrl, 'Descripción (opcional)', Icons.notes_outlined),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _campo(cantidadCtrl, 'Cantidad comprada', Icons.numbers,
                  tipo: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _campo(precioCtrl, 'Precio unitario (\$)', Icons.attach_money,
                  tipo: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            _campo(unidadCtrl, 'Unidad (ej: unidad, kg, litro)', Icons.straighten),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorPrimario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final descripcion = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                  if (insumo == null) {
                    final datos = construirPayloadCrearInsumo(
                      tenantId: kTenantIdActivo,
                      creadoPor: perfil!.id,
                      nombre: nombreCtrl.text.trim(),
                      descripcion: descripcion,
                      cantidad: int.tryParse(cantidadCtrl.text) ?? 0,
                      precio: double.tryParse(precioCtrl.text) ?? 0,
                      unidad: unidadCtrl.text.trim(),
                    );
                    await _client.from('supplies').insert(datos);
                    ServicioActividad.instancia.registrarFeature('crear_insumo');
                  } else {
                    final datos = {
                      'name': nombreCtrl.text.trim(),
                      'description': descripcion,
                      'stock': int.tryParse(cantidadCtrl.text) ?? 0,
                      'price': double.tryParse(precioCtrl.text) ?? 0,
                      'unit': unidadCtrl.text.trim(),
                      'status': 'active',
                    };
                    await _client.from('supplies')
                        .update(datos).eq('id', insumo['id']);
                    ServicioActividad.instancia.registrarFeature('editar_insumo');
                  }
                  _cargar();
                },
                child: Text(insumo == null ? 'Registrar' : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, IconData icon,
      {TextInputType tipo = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(color: Color(0xFF1C1C1E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kTextSub),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: kTextSub),
      ),
    );
  }

  Future<void> _eliminar(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar compra',
            style: TextStyle(color: Color(0xFF1C1C1E))),
        content: const Text('¿Seguro que quieres eliminar este registro?',
            style: TextStyle(color: Color(0xFF1C1C1E))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _client.from('supplies').delete().eq('id', id);
      _cargar();
    }
  }

  String _fmtFecha(String? iso) {
    final dt = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colorPrimario;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Insumos'),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_outlined, color: kTextSub),
          ),
          IconButton(
            onPressed: () => _mostrarFormulario(),
            icon: Icon(Icons.add_circle_outline, color: color),
          ),
        ],
      ),
      body: EnvolturaResponsiva(
        child: SafeArea(
        child: Column(
          children: [
            // Total comprado
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.receipt_long_outlined, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text('Total comprado: \$${_totalComprado.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                style: const TextStyle(color: Color(0xFF1C1C1E)),
                decoration: InputDecoration(
                  hintText: 'Buscar insumo...',
                  hintStyle: const TextStyle(color: kTextSub),
                  prefixIcon: const Icon(Icons.search, color: kTextSub),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Lista
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _filtrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 56, color: color.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text('Sin compras registradas',
                                  style: TextStyle(color: kTextSub)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) => _TarjetaInsumo(
                            insumo: _filtrados[i],
                            color: color,
                            fecha: _fmtFecha(_filtrados[i]['created_at'] as String?),
                            onEditar: () => _mostrarFormulario(insumo: _filtrados[i]),
                            onEliminar: () => _eliminar(_filtrados[i]['id']),
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

class _TarjetaInsumo extends StatelessWidget {
  final Map<String, dynamic> insumo;
  final Color color;
  final String fecha;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaInsumo({
    required this.insumo,
    required this.color,
    required this.fecha,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cantidad = insumo['stock'] as int? ?? 0;
    final precio = (insumo['price'] as num?)?.toDouble() ?? 0;
    final unidad = insumo['unit'] as String? ?? 'unidad';
    final total = precio * cantidad;

    return GestureDetector(
      onTap: onEditar,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(insumo['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E))),
              const SizedBox(height: 2),
              Text('$cantidad $unidad × \$${precio.toStringAsFixed(2)} · $fecha',
                  style: const TextStyle(color: kTextSub, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Row(children: [
              GestureDetector(
                onTap: onEditar,
                child: Icon(Icons.edit_outlined, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEliminar,
                child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }
}
