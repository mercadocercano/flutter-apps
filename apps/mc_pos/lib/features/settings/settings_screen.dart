import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_design_system/mc_design_system.dart';
import '../../widgets/pos/pos_modal.dart';
import '../auth/auth_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _storeName = '';
  String _storeAddress = '';
  String _storePhone = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final port = context.read<TenantConfigPort>();
      final results = await Future.wait([
        port.getConfig('store.name'),
        port.getConfig('store.address'),
        port.getConfig('store.phone'),
      ]);
      setState(() {
        _storeName = results[0] ?? '';
        _storeAddress = results[1] ?? '';
        _storePhone = results[2] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los datos del comercio.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig(String key, String value, String fieldLabel) async {
    try {
      await context.read<TenantConfigPort>().setConfig(key, value);
      setState(() {
        switch (key) {
          case 'store.name':
            _storeName = value;
          case 'store.address':
            _storeAddress = value;
          case 'store.phone':
            _storePhone = value;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fieldLabel actualizado'),
            backgroundColor: McColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar. Revisá tu conexión.'),
            backgroundColor: McColors.error,
          ),
        );
      }
    }
  }

  void _showEdit(
    BuildContext context,
    String fieldLabel,
    String currentValue,
    String configKey,
  ) {
    final controller = TextEditingController(text: currentValue);
    showPosDialog<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fieldLabel,
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
                    final newValue = controller.text.trim();
                    Navigator.of(context).pop();
                    _saveConfig(configKey, newValue, fieldLabel);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: McColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadSettings)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(McSpacing.md),
      children: [
        _SectionHeader('Mi comercio'),
        _SettingsTile(
          icon: Icons.store,
          title: _storeName.isNotEmpty ? _storeName : 'Sin nombre',
          subtitle: 'Nombre del comercio',
          onTap: () =>
              _showEdit(context, 'Nombre del comercio', _storeName, 'store.name'),
        ),
        _SettingsTile(
          icon: Icons.location_on,
          title: _storeAddress.isNotEmpty ? _storeAddress : 'Sin dirección',
          subtitle: 'Dirección',
          onTap: () => _showEdit(context, 'Dirección', _storeAddress, 'store.address'),
        ),
        _SettingsTile(
          icon: Icons.phone,
          title: _storePhone.isNotEmpty ? _storePhone : 'Sin teléfono',
          subtitle: 'Teléfono / WhatsApp',
          onTap: () =>
              _showEdit(context, 'Teléfono', _storePhone, 'store.phone'),
        ),
        const Divider(height: McSpacing.xl),

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

        McButton(
          label: 'Cerrar sesión',
          icon: Icons.logout,
          variant: McButtonVariant.outline,
          expand: true,
          onPressed: () => context.read<AuthCubit>().logout(),
        ),
        const SizedBox(height: McSpacing.xl),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: McSpacing.md),
            McButton(label: 'Reintentar', onPressed: onRetry),
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
