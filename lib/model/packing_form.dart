import 'package:deep_pick/deep_pick.dart';

class PackingForm {
  final String name;
  final int order;

  const PackingForm({required this.name, required this.order});

  @override
  String toString() => 'PackingForm(name: $name, order: $order)';

  dynamic toJson() => {
        'name': name,
        'order': order,
      };

  static PackingForm fromPick(Pick pick) => PackingForm(
      name: pick('name').asStringOrThrow(),
      order: pick('order').asIntOrThrow());
}
