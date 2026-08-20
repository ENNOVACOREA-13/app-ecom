import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/employee_repository.dart';
import '../../providers/auth_provider.dart';
import '../../core/entrada_animada.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';
import '../common/toast.dart';

class PaginaDiasLibres extends StatefulWidget {
  const PaginaDiasLibres({super.key});

  @override
  State<PaginaDiasLibres> createState() => _PaginaDiasLibresState();
}

class _PaginaDiasLibresState extends State<PaginaDiasLibres> {
  final _repo = RepositorioEmpleado();
  List<Map<String, dynamic>> _diasLibres = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final id = context.read<ProveedorAuth>().perfil?.id;
    if (id == null) return;
    setState(() => _cargando = true);
    try {
      final datos = await _repo.obtenerDiasLibres(id);
      if (mounted) setState(() => _diasLibres = datos);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregarDiaLibre() async {
    final id = context.read<ProveedorAuth>().perfil?.id;
    if (id == null) return;
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 1)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 180)),
    );
    if (fecha == null || !mounted) return;

    final ctrlMotivo = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Marcar día libre', style: TextStyle(color: Color(0xFF1C1C1E))),
        content: TextField(
          controller: ctrlMotivo,
          style: const TextStyle(color: Color(0xFF1C1C1E)),
          decoration: InputDecoration(
            labelText: 'Motivo (opcional)',
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    try {
      await _repo.agregarDiaLibre(
        idEmpleado: id,
        fecha: fecha,
        motivo: ctrlMotivo.text.trim().isEmpty ? null : ctrlMotivo.text.trim(),
      );
      if (mounted) {
        mostrarToast(context, 'Día libre agregado', tipo: TipoToast.exito);
        _cargar();
      }
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
      }
    }
  }

  Future<void> _eliminarDiaLibre(String id) async {
    try {
      await _repo.eliminarDiaLibre(id);
      _cargar();
    } catch (e) {
      if (mounted) {
        mostrarToast(context, 'Error: $e', tipo: TipoToast.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE d 'de' MMMM", 'es_ES');
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Días libres'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarDiaLibre,
        backgroundColor: context.colorPrimario,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: EnvolturaResponsiva(
        child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _diasLibres.isEmpty
              ? const EstadoVacio(
                  icono: Icons.event_available_outlined,
                  titulo: 'Sin días libres marcados',
                  subtitulo: 'Toca + para marcar una fecha en la que no estarás disponible',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: _diasLibres.length,
                  itemBuilder: (_, i) {
                    final d = _diasLibres[i];
                    final fecha = DateTime.parse(d['date'] as String);
                    final motivo = d['reason'] as String?;
                    final texto = fmt.format(fecha);
                    return EntradaAnimada(
                      index: i,
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: kNeumorphicShadowsSmall,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colorPrimario.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.event_busy_outlined,
                                color: context.colorPrimario, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  texto[0].toUpperCase() + texto.substring(1),
                                  style: const TextStyle(
                                      color: Color(0xFF1C1C1E),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                if (motivo != null && motivo.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(motivo,
                                      style: const TextStyle(
                                          color: Color(0xFF8E8E93), fontSize: 11)),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _eliminarDiaLibre(d['id'] as String),
                          ),
                        ],
                      ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
