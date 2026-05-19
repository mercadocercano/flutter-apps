import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_design_system/mc_design_system.dart';
import '../../widgets/pos/pos_modal.dart';
import '../auth/auth_cubit.dart';

/// Pantalla de configuración — datos del comercio, cuenta, soporte.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(McSpacing.md),
        children: [
          // Datos del comercio
          _SectionHeader('Mi comercio'),
          _SettingsTile(
            icon: Icons.store,
            title: 'Almacén Don Pedro',
            subtitle: 'Nombre del comercio',
            onTap: () => _showEdit(context, 'Nombre del comercio', 'Almacén Don Pedro'),
          ),
          _SettingsTile(
            icon: Icons.location_on,
            title: 'Av. San Martín 1234, Posadas',
            subtitle: 'Dirección',
            onTap: () => _showEdit(context, 'Dirección', 'Av. San Martín 1234'),
          ),
          _SettingsTile(
            icon: Icons.phone,
            title: '3764-551234',
            subtitle: 'Teléfono / WhatsApp',
            onTap: () => _showEdit(context, 'Teléfono', '3764-551234'),
          ),
          const Divider(height: McSpacing.xl),

          // Cuenta
          _SectionHeader('Mi cuenta'),
          _SettingsTile(
            icon: Icons.person,
            title: 'Pedro González',
            subtitle: 'pedro@email.com',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock,
            title: 'Cambiar contraseña',
            onTap: () {},
          ),
          const Divider(height: McSpacing.xl),

          // POS Config
          _SectionHeader('Punto de venta'),
          _SettingsSwitch(
            icon: Icons.receipt_long,
            title: 'Imprimir ticket automático',
            subtitle: 'Imprime al completar venta',
            value: false,
            onChanged: (v) {},
          ),
          _SettingsSwitch(
            icon: Icons.dark_mode,
            title: 'Modo oscuro',
            subtitle: 'Mejor para ambientes con poca luz',
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (v) {},
          ),
          _SettingsSwitch(
            icon: Icons.vibration,
            title: 'Sonido al escanear',
            subtitle: 'Vibración y beep al leer código',
            value: true,
            onChanged: (v) {},
          ),
          const Divider(height: McSpacing.xl),

          // Info
          _SectionHeader('Información'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Ayuda y soporte',
            subtitle: 'WhatsApp: 3764-000000',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Versión',
            subtitle: 'MC POS v0.1.0',
            onTap: () {},
          ),
          const SizedBox(height: McSpacing.lg),

          // Cerrar sesión
          McButton(
            label: 'Cerrar sesión',
            icon: Icons.logout,
            variant: McButtonVariant.outline,
            expand: true,
            onPressed: () {
              context.read<AuthCubit>().logout();
            },
          ),
          const SizedBox(height: McSpacing.xl),
        ],
      ),
    );
  }

  void _showEdit(BuildContext context, String field, String current) {
    final controller = TextEditingController(text: current);
    showPosDialog<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: McColors.foregroundLight,
              ),
            ),
            const SizedBox(height: McSpacing.md),
            McTextField(controller: controller, autofocus: true),
            const SizedBox(height: McSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                McButton(
                  label: 'Cancelar',
                  variant: McButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: McSpacing.sm),
                McButton(
                  label: 'Guardar',
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$field actualizado'),
                        backgroundColor: McColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: McSpacing.sm,
        bottom: McSpacing.sm,
        left: McSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: McColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: McColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: McColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
