import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/template_form_bloc.dart';

/// Bottom sheet para generar una plantilla con IA.
///
/// Muestra un campo de descripción, un botón "Generar" y el spinner mientras
/// la IA procesa. Al recibir [TemplateFormAISuccess] cierra el sheet; el padre
/// [TemplateFormScreen] pre-completa el formulario con los datos sugeridos.
class AIGenerationSheet extends StatefulWidget {
  final String businessTypeId;

  const AIGenerationSheet({super.key, required this.businessTypeId});

  @override
  State<AIGenerationSheet> createState() => _AIGenerationSheetState();
}

class _AIGenerationSheetState extends State<AIGenerationSheet> {
  final _descriptionController = TextEditingController();
  String? _validationError;

  static const int _minDescriptionLength = 20;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _generate() {
    final text = _descriptionController.text.trim();
    if (text.length < _minDescriptionLength) {
      setState(() {
        _validationError =
            'Describí tu tipo de negocio con al menos $_minDescriptionLength caracteres';
      });
      return;
    }
    setState(() => _validationError = null);

    context.read<TemplateFormBloc>().add(
          GenerateWithAIEvent(
            description: text,
            businessTypeId: widget.businessTypeId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TemplateFormBloc, TemplateFormState>(
      listener: (context, state) {
        if (state is TemplateFormAISuccess || state is TemplateFormError) {
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<TemplateFormBloc, TemplateFormState>(
        builder: (context, state) {
          final isGenerating = state is TemplateFormAIGenerating;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildDescriptionField(enabled: !isGenerating),
                if (_validationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildGenerateButton(isGenerating),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome_outlined),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Generar plantilla con IA',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField({required bool enabled}) {
    return TextField(
      controller: _descriptionController,
      enabled: enabled,
      maxLines: 5,
      minLines: 3,
      decoration: const InputDecoration(
        labelText: 'Describí tu tipo de negocio',
        hintText:
            'Ej: Ferretería mediana en zona urbana, principalmente tornillos, '
            'herramientas manuales y electricidad...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildGenerateButton(bool isGenerating) {
    if (isGenerating) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'La IA está generando tu plantilla...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _generate,
      icon: const Icon(Icons.auto_awesome_outlined),
      label: const Text('Generar'),
    );
  }
}
