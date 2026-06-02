/// Dato de una estadística individual dentro de un [StatsSectionCard].
class StatItem {
  final String label;
  final int value;
  final String? subtitle;

  const StatItem({
    required this.label,
    required this.value,
    this.subtitle,
  });
}
