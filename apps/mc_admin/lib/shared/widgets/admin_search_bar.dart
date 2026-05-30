import 'dart:async';
import 'package:flutter/material.dart';

/// Barra de búsqueda con debounce configurable (default 300ms).
class AdminSearchBar extends StatefulWidget {
  final String hint;
  final String initialValue;
  final Duration debounceDuration;
  final void Function(String query) onSearch;

  const AdminSearchBar({
    super.key,
    required this.onSearch,
    this.hint = 'Buscar...',
    this.initialValue = '',
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () => widget.onSearch(value));
  }

  void _onClear() {
    _controller.clear();
    _debounce?.cancel();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: _onClear,
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
