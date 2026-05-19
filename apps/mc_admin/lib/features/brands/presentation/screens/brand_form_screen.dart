import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../../domain/models/brand_model.dart';
import '../bloc/brands_bloc.dart';
import '../../../../shared/widgets/admin_modal.dart';

// Google Fonts disponibles para marcas (subset curado, compatible google_fonts)
const _availableFonts = [
  'Poppins',
  'Inter',
  'Oswald',
  'Roboto',
  'Montserrat',
  'Lato',
  'Open Sans',
  'Raleway',
  'Playfair Display',
  'Nunito',
  'Barlow',
  'DM Sans',
  'Ubuntu',
  'Mukta',
  'Bebas Neue',
  'Abril Fatface',
  'Pacifico',
];

// Paleta de 20 colores comunes para marcas
const _palette = [
  '#FFFFFF', '#000000', '#E61A27', '#003DA5', '#006B3C',
  '#FFD700', '#FF6600', '#7B2D8E', '#003399', '#CC0000',
  '#1A1F71', '#006837', '#8B0000', '#F57C20', '#00529B',
  '#4A2C2A', '#1D4731', '#FFCC00', '#D40000', '#333333',
];

Color _hexColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return fallback;
  return Color(int.parse('FF$h', radix: 16));
}

String _normalizeHex(String raw) {
  final h = raw.trim().replaceFirst('#', '');
  if (h.length == 6) return '#${h.toUpperCase()}';
  return raw.trim();
}

// ---------------------------------------------------------------------------
// SimpleColorPicker
// ---------------------------------------------------------------------------

class _SimpleColorPicker extends StatefulWidget {
  final String? initial;
  final ValueChanged<String> onApply;

  const _SimpleColorPicker({this.initial, required this.onApply});

  @override
  State<_SimpleColorPicker> createState() => _SimpleColorPickerState();
}

class _SimpleColorPickerState extends State<_SimpleColorPicker> {
  late String _selected;
  late TextEditingController _hexController;
  String? _hexError;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial ?? '#FFFFFF';
    _hexController = TextEditingController(text: _selected);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  bool _isValidHex(String value) {
    final h = value.replaceFirst('#', '');
    return h.length == 6 &&
        RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(h);
  }

  void _onHexSubmit(String value) {
    final normalized = _normalizeHex(value);
    if (_isValidHex(normalized)) {
      setState(() {
        _selected = normalized;
        _hexController.text = normalized;
        _hexError = null;
      });
      widget.onApply(_selected);
    } else {
      setState(() => _hexError = 'Formato invalido. Ej: #FF0000');
    }
  }

  void _onPaletteSelect(String hex) {
    setState(() {
      _selected = hex;
      _hexController.text = hex;
      _hexError = null;
    });
    widget.onApply(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _hexColor(_selected, Colors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid de paleta
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _palette.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, index) {
            final hex = _palette[index];
            final color = _hexColor(hex, Colors.white);
            final isSelected = hex == _selected;
            return GestureDetector(
              onTap: () => _onPaletteSelect(hex),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black.withValues(alpha: 0.15),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Input hex manual
        TextField(
          controller: _hexController,
          decoration: InputDecoration(
            labelText: 'Hex manual',
            hintText: '#FFFFFF',
            border: const OutlineInputBorder(),
            isDense: true,
            errorText: _hexError,
          ),
          onSubmitted: _onHexSubmit,
          onChanged: (v) {
            if (_isValidHex(v)) _onHexSubmit(v);
          },
        ),
        const SizedBox(height: 12),
        // Preview
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: previewColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Text(
            _selected,
            style: TextStyle(
              color: previewColor.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _ColorField — fila con preview cuadrado + hex + botón Cambiar
// ---------------------------------------------------------------------------

class _ColorField extends StatelessWidget {
  final String label;
  final String? currentHex;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _ColorField({
    required this.label,
    required this.currentHex,
    required this.enabled,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    String? result = currentHex;
    await showAdminDialog<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(McSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: McColors.foregroundLight,
              ),
            ),
            const SizedBox(height: McSpacing.md),
            SizedBox(
              width: 280,
              child: _SimpleColorPicker(
                initial: currentHex,
                onApply: (hex) => result = hex,
              ),
            ),
            const SizedBox(height: McSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: McSpacing.sm),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (result != null) onChanged(result!);
                  },
                  child: const Text('Aplicar'),
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
    final color = _hexColor(currentHex, const Color(0xFFF1F5F9));
    final displayText = currentHex?.isNotEmpty == true ? currentHex! : 'Sin color';

    return Row(
      children: [
        // Preview cuadrado
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                displayText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: enabled ? () => _openPicker(context) : null,
          child: const Text('Cambiar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BrandFormScreen
// ---------------------------------------------------------------------------

class BrandFormScreen extends StatefulWidget {
  final String? brandId;

  const BrandFormScreen({super.key, this.brandId});

  bool get isEditing => brandId != null;

  @override
  State<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends State<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _backgroundColor;
  String? _textColor;
  String? _typography;

  bool _listening = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _prefillFromBloc();
    }
  }

  void _prefillFromBloc() {
    final state = context.read<BrandsBloc>().state;
    if (state is BrandsLoaded) {
      final brand = state.brands.where((b) => b.id == widget.brandId).firstOrNull;
      if (brand != null) _fillFields(brand);
    }
  }

  void _fillFields(Brand brand) {
    _nameController.text = brand.name;
    _descriptionController.text = brand.description ?? '';
    _logoUrlController.text = brand.logoUrl ?? '';
    _websiteController.text = brand.website ?? '';
    setState(() {
      _backgroundColor = brand.backgroundColor;
      _textColor = brand.textColor;
      // Normalizar: si la tipografía guardada está en la lista la seleccionamos
      final saved = brand.typography;
      _typography = (saved != null && _availableFonts.contains(saved)) ? saved : null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final brand = Brand(
      id: widget.brandId ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      logoUrl: _logoUrlController.text.trim().isEmpty
          ? null
          : _logoUrlController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      backgroundColor: _backgroundColor?.isEmpty == true ? null : _backgroundColor,
      textColor: _textColor?.isEmpty == true ? null : _textColor,
      typography: _typography,
    );

    setState(() => _listening = true);

    if (widget.isEditing) {
      context
          .read<BrandsBloc>()
          .add(UpdateBrandEvent(id: widget.brandId!, brand: brand));
    } else {
      context.read<BrandsBloc>().add(CreateBrandEvent(brand));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BrandsBloc, BrandsState>(
      listener: (context, state) {
        if (!_listening) return;
        if (state is BrandsLoaded) {
          context.go('/brands');
        } else if (state is BrandsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: McColors.error),
          );
          setState(() => _listening = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Editar marca' : 'Nueva marca'),
        ),
        body: BlocBuilder<BrandsBloc, BrandsState>(
          builder: (context, state) {
            final isLoading = state is BrandsLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre',
                      required: true,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Descripcion',
                      maxLines: 3,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _logoUrlController,
                      label: 'URL del logo',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Sitio web',
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Identidad visual'),
                      tilePadding: EdgeInsets.zero,
                      initiallyExpanded:
                          _backgroundColor != null || _textColor != null,
                      children: [
                        _ColorField(
                          label: 'Color de fondo',
                          currentHex: _backgroundColor,
                          enabled: !isLoading,
                          onChanged: (hex) =>
                              setState(() => _backgroundColor = hex),
                        ),
                        const SizedBox(height: 12),
                        _ColorField(
                          label: 'Color de texto',
                          currentHex: _textColor,
                          enabled: !isLoading,
                          onChanged: (hex) =>
                              setState(() => _textColor = hex),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _typography,
                          decoration: const InputDecoration(
                            labelText: 'Tipografia',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Sin tipografia (hereda tema)'),
                            ),
                            ..._availableFonts.map(
                              (font) => DropdownMenuItem<String>(
                                value: font,
                                child: Text(font),
                              ),
                            ),
                          ],
                          onChanged: isLoading
                              ? null
                              : (val) => setState(() => _typography = val),
                        ),
                        const SizedBox(height: 12),
                        // Preview en tiempo real
                        if (_nameController.text.isNotEmpty ||
                            _backgroundColor != null ||
                            _textColor != null)
                          _BrandPreview(
                            name: _nameController.text.isEmpty
                                ? 'Nombre de marca'
                                : _nameController.text,
                            backgroundColor: _backgroundColor,
                            textColor: _textColor,
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => context.pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _save,
                            child: isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
    bool enabled = true,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label es obligatorio';
              }
              return null;
            }
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// _BrandPreview — preview en tiempo real dentro del form
// ---------------------------------------------------------------------------

class _BrandPreview extends StatelessWidget {
  final String name;
  final String? backgroundColor;
  final String? textColor;

  const _BrandPreview({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _hexColor(backgroundColor, const Color(0xFFF1F5F9));
    final fg = _hexColor(textColor, const Color(0xFF334155));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vista previa',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Text(
            name,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
