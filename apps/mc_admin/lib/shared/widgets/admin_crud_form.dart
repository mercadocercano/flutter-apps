import 'package:flutter/material.dart';

/// Wrapper de formulario para pantallas de crear/editar.
/// Maneja estado de submit (loading/error) y botones Guardar/Cancelar.
class AdminCrudForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final String cancelLabel;
  final List<Widget> children;
  final double maxWidth;

  const AdminCrudForm({
    super.key,
    required this.formKey,
    required this.title,
    required this.onSave,
    required this.onCancel,
    required this.children,
    this.isLoading = false,
    this.errorMessage,
    this.saveLabel = 'Guardar',
    this.cancelLabel = 'Cancelar',
    this.maxWidth = 640,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isLoading ? null : onCancel,
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: onSave,
              child: Text(saveLabel),
            ),
        ],
      ),
      body: Form(
        key: formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...children,
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: isLoading ? null : onCancel,
                        child: Text(cancelLabel),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: isLoading ? null : onSave,
                        child: Text(saveLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
