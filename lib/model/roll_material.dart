import 'package:deep_pick/deep_pick.dart';

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

  dynamic toJson() => {
        'name': name,
        'grammage': grammage,
        'productCode': productCode,
      };

  factory RollMaterial.fromPick(Pick pick) => RollMaterial(
      name: pick('name').asStringOrThrow(),
      grammage: pick('grammage').asDoubleOrNull(),
      productCode: pick('productCode').asStringOrNull());
}
