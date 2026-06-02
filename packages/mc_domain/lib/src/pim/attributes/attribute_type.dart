/// Tipo de dato de un atributo del marketplace.
enum AttributeType {
  text,
  number,
  boolean,
  select,
  multiSelect;

  static AttributeType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'text' => AttributeType.text,
      'number' => AttributeType.number,
      'boolean' => AttributeType.boolean,
      'select' => AttributeType.select,
      'multi_select' => AttributeType.multiSelect,
      _ => AttributeType.text,
    };
  }

  String toApiString() => switch (this) {
        AttributeType.text => 'text',
        AttributeType.number => 'number',
        AttributeType.boolean => 'boolean',
        AttributeType.select => 'select',
        AttributeType.multiSelect => 'multi_select',
      };

  /// Indica si el tipo admite valores enumerados (select/multiSelect).
  bool get hasValues =>
      this == AttributeType.select || this == AttributeType.multiSelect;
}
