import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_widgets.dart';

class PaginaPerfil extends StatefulWidget {
  const PaginaPerfil({super.key});

  @override
  State<PaginaPerfil> createState() => _PaginaPerfilState();
}

class _PaginaPerfilState extends State<PaginaPerfil> {
  final _ctrlNombre = TextEditingController();
  final _ctrlTelefono = TextEditingController();
  final _ctrlBio = TextEditingController();
  bool _editando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<ProveedorAuth>().perfil;
    _ctrlNombre.text = perfil?.nombreCompleto ?? '';
    _ctrlTelefono.text = perfil?.telefono ?? '';
    _ctrlBio.text = perfil?.bio ?? '';
  }

  @override
  void dispose() {
    _ctrlNombre.dispose();
    _ctrlTelefono.dispose();
    _ctrlBio.dispose();
    super.dispose();
  }

  Future<void> _elegirAvatar() async {
    final selector = ImagePicker();
    final xArchivo = await selector.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (xArchivo == null || !mounted) return;
    final Uint8List bytes = await xArchivo.readAsBytes();
    final mimeType = xArchivo.mimeType ?? 'image/jpeg';
    final ext = mimeType.contains('/') ? mimeType.split('/').last : 'jpeg';
    if (mounted) {
      await context.read<ProveedorAuth>().subirAvatar(bytes, ext);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada')),
      );
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await context.read<ProveedorAuth>().actualizarPerfil({
      'full_name': _ctrlNombre.text.trim(),
      'phone': _ctrlTelefono.text.trim(),
      'bio': _ctrlBio.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _editando = false;
    });
  }

  Future<void> _salir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await context.read<ProveedorAuth>().cerrarSesion();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorAuth>().perfil;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editando = true),
            )
          else
            TextButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: _elegirAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AvatarRed(url: perfil?.urlAvatar, nombre: perfil?.nombreCompleto, radio: 48),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (!_editando) ...[
              Text(
                perfil?.nombreCompleto ?? '',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
              ),
              const SizedBox(height: 4),
              _ChipRol(rol: perfil?.rol.toDbString() ?? 'client'),
            ],
            const SizedBox(height: 24),

            if (_editando)
              Column(
                children: [
                  CampoTexto(etiqueta: 'Nombre completo', controlador: _ctrlNombre),
                  const SizedBox(height: 12),
                  CampoTexto(
                      etiqueta: 'Teléfono',
                      controlador: _ctrlTelefono,
                      tipoTeclado: TextInputType.phone),
                  const SizedBox(height: 12),
                  CampoTexto(
                    etiqueta: 'Bio / Descripción',
                    controlador: _ctrlBio,
                    maxLineas: 3,
                  ),
                ],
              )
            else ...[
              TarjetaSeccion(
                child: Column(
                  children: [
                    _FilaInfo(
                      Icons.person_outline,
                      'Nombre completo',
                      perfil?.nombreCompleto.isNotEmpty == true
                          ? perfil!.nombreCompleto
                          : '—',
                    ),
                    const Divider(height: 24),
                    _FilaInfo(
                      Icons.email_outlined,
                      'Email',
                      Supabase.instance.client.auth.currentUser?.email ?? '—',
                    ),
                    const Divider(height: 24),
                    _FilaInfo(
                      Icons.phone_outlined,
                      'Teléfono',
                      perfil?.telefono?.isNotEmpty == true
                          ? perfil!.telefono!
                          : '—',
                    ),
                    if (perfil?.bio != null && perfil!.bio!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _FilaInfo(Icons.info_outline, 'Bio', perfil.bio!),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Logout
            OutlinedButton.icon(
              onPressed: _salir,
              icon: const Icon(Icons.logout, color: Color(0xFF6E6E73)),
              label: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFF6E6E73))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kDivider),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaInfo(this.icono, this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: kTextSub),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: const TextStyle(color: kTextMuted, fontSize: 11)),
            Text(valor, style: const TextStyle(color: kText, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _ChipRol extends StatelessWidget {
  final String rol;
  const _ChipRol({required this.rol});

  @override
  Widget build(BuildContext context) {
    final etiquetas = {
      'client': 'Cliente',
      'employee': 'Empleado',
      'admin': 'Admin',
      'super_admin': 'Super Admin',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiquetas[rol] ?? rol,
        style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
