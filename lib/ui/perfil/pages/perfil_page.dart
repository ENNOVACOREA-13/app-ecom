import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/auth_repository.dart';
import '../../../domain/app_context.dart';
import '../../theme/app_theme.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _auth = RepositorioAuth();
  bool _cargando = false;

  Future<void> _cerrarSesion() async {
    setState(() => _cargando = true);
    try {
      await _auth.cerrarSesion();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _getRolLabel(String rol) {
    switch (rol.toLowerCase()) {
      case 'usuario':
        return 'Usuario';
      case 'empleado':
        return 'Empleado (Barbero)';
      case 'admin':
        return 'Administrador';
      case 'admin_supremo':
        return 'Administrador Supremo';
      default:
        return 'Usuario';
    }
  }

  IconData _getRolIcon(String rol) {
    switch (rol.toLowerCase()) {
      case 'empleado':
        return Icons.cut;
      case 'admin':
      case 'admin_supremo':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Sin correo';
    final rol = context.watch<ContextoApp>().rol;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar:
          AppBar(backgroundColor: AppColors.black, title: const Text('Perfil')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      email.isNotEmpty ? email[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 36, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: const Icon(Icons.email, color: AppColors.primary),
                    title: const Text('Correo electrónico',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(email,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: Icon(_getRolIcon(rol), color: AppColors.primary),
                    title: const Text('Rol',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(_getRolLabel(rol),
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
