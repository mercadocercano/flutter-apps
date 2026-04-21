/// Estados de un producto con máquina de estados.
enum ProductStatus {
  draft,
  pending,
  active,
  inactive,
  discontinued,
  deleted;

  static const _transitions = {
    draft: {pending, active, deleted},
    pending: {active, draft, deleted},
    active: {inactive, discontinued, deleted},
    inactive: {active, discontinued, deleted},
    discontinued: {deleted},
    deleted: <ProductStatus>{},
  };

  bool canTransitionTo(ProductStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  bool get isSellable => this == active;
  bool get isVisible => this == active || this == inactive;
}
