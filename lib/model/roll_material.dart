class RollMaterial {
  final String name;
  final double? grammage;
  final String? productCode;

  const RollMaterial({
    required this.name,
    this.grammage,
    this.productCode,
  });

  @override
  String toString() =>
      'RollMaterial(name: $name, grammage: $grammage, productCode: $productCode)';
}
