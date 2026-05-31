import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';

// --- Events ---

abstract class TaxonomyEvent {}

class LoadTaxonomyEvent extends TaxonomyEvent {}

class SearchCategoriesEvent extends TaxonomyEvent {
  final String query;
  SearchCategoriesEvent(this.query);
}

class ToggleCategoryExpansionEvent extends TaxonomyEvent {
  final String id;
  ToggleCategoryExpansionEvent(this.id);
}

class RefreshTaxonomyEvent extends TaxonomyEvent {}

// --- States ---

abstract class TaxonomyState {}

class TaxonomyInitial extends TaxonomyState {}

class TaxonomyLoading extends TaxonomyState {}

class TaxonomyLoaded extends TaxonomyState {
  final CategoryTree tree;
  final Set<String> expandedIds;
  final String? searchQuery;

  TaxonomyLoaded({
    required this.tree,
    this.expandedIds = const {},
    this.searchQuery,
  });

  TaxonomyLoaded withSearch(String? searchQuery) {
    return TaxonomyLoaded(
      tree: tree,
      expandedIds: expandedIds,
      searchQuery: searchQuery,
    );
  }

  TaxonomyLoaded copyWith({
    CategoryTree? tree,
    Set<String>? expandedIds,
    Set<String>? expandedIdsOverride,
  }) {
    return TaxonomyLoaded(
      tree: tree ?? this.tree,
      expandedIds: expandedIdsOverride ?? expandedIds ?? this.expandedIds,
      searchQuery: searchQuery,
    );
  }
}

class TaxonomyError extends TaxonomyState {
  final String message;
  TaxonomyError(this.message);
}

// --- Bloc ---

class TaxonomyBloc extends Bloc<TaxonomyEvent, TaxonomyState> {
  final GetCategoryTreeUseCase _getTree;

  TaxonomyBloc({required GetCategoryTreeUseCase getTree})
      : _getTree = getTree,
        super(TaxonomyInitial()) {
    on<LoadTaxonomyEvent>(_onLoad);
    on<RefreshTaxonomyEvent>(_onRefresh);
    on<SearchCategoriesEvent>(_onSearch);
    on<ToggleCategoryExpansionEvent>(_onToggleExpansion);
  }

  Future<void> _onLoad(
    LoadTaxonomyEvent event,
    Emitter<TaxonomyState> emit,
  ) async {
    emit(TaxonomyLoading());
    try {
      final tree = await _getTree.execute();
      emit(TaxonomyLoaded(tree: tree));
    } catch (e) {
      emit(TaxonomyError('Error al cargar taxonomía: $e'));
    }
  }

  Future<void> _onRefresh(
    RefreshTaxonomyEvent event,
    Emitter<TaxonomyState> emit,
  ) async {
    final current = state;
    final prevExpanded =
        current is TaxonomyLoaded ? current.expandedIds : const <String>{};

    emit(TaxonomyLoading());
    try {
      final tree = await _getTree.execute();
      emit(TaxonomyLoaded(tree: tree, expandedIds: Set.from(prevExpanded)));
    } catch (e) {
      emit(TaxonomyError('Error al recargar taxonomía: $e'));
    }
  }

  void _onSearch(
    SearchCategoriesEvent event,
    Emitter<TaxonomyState> emit,
  ) {
    final current = state;
    if (current is! TaxonomyLoaded) return;

    final query = event.query.trim();
    emit(current.withSearch(query.isEmpty ? null : query));
  }

  void _onToggleExpansion(
    ToggleCategoryExpansionEvent event,
    Emitter<TaxonomyState> emit,
  ) {
    final current = state;
    if (current is! TaxonomyLoaded) return;

    final expanded = Set<String>.from(current.expandedIds);
    if (expanded.contains(event.id)) {
      expanded.remove(event.id);
    } else {
      expanded.add(event.id);
    }
    emit(current.copyWith(expandedIdsOverride: expanded));
  }
}
