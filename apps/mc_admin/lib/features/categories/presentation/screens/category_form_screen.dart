import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mc_design_system/mc_design_system.dart';

import '../../domain/models/category_model.dart';
import '../bloc/categories_bloc.dart';

class CategoryFormScreen extends StatefulWidget {
  final String? categoryId;
  final String? initialParentId;

  const CategoryFormScreen({
    super.key,
    this.categoryId,
    this.initialParentId,
  });

  bool get isEditing => categoryId != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _slugController = TextEditingController();

  String? _selectedParentId;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.initialParentId;

    _nameController.addListener(_autoGenerateSlug);

    if (widget.isEditing) {
      _prefillFromBloc();
    }
  }

  void _autoGenerateSlug() {
    if (widget.isEditing) return;
    final slug = _nameController.text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    _slugController.text = slug;
  }

  void _prefillFromBloc() {
    final state = context.read<CategoriesBloc>().state;
    if (state is CategoriesLoaded) {
      final cat =
          state.categories.where((c) => c.id == widget.categoryId).firstOrNull;
      if (cat != null) {
        _nameController.text = cat.name;
        _descriptionController.text = cat.description ?? '';
        _slugController.text = cat.slug;
        _selectedParentId = cat.parentId;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final category = Category(
      id: widget.categoryId ?? '',
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      parentId: _selectedParentId,
    );

    setState(() => _listening = true);

    if (widget.isEditing) {
      context.read<CategoriesBloc>().add(
            UpdateCategoryEvent(id: widget.categoryId!, category: category),
          );
    } else {
      context.read<CategoriesBloc>().add(CreateCategoryEvent(category));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (!_listening) return;
        if (state is CategoriesLoaded) {
          context.go('/categories');
        } else if (state is CategoriesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: McColors.error),
          );
          setState(() => _listening = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Editar categoria' : 'Nueva categoria'),
        ),
        body: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            final isLoading = state is CategoriesLoading;
            final categories =
                state is CategoriesLoaded ? state.categories : <Category>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nombre es obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _slugController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Slug',
                        hintText: 'se-genera-automaticamente',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isLoading,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedParentId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria padre',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin padre (raiz)'),
                        ),
                        ...categories
                            .where((c) => c.id != widget.categoryId)
                            .map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(
                                  '${'  ' * c.level}${c.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                      ],
                      onChanged: isLoading
                          ? null
                          : (val) => setState(() => _selectedParentId = val),
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
}
