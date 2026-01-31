import 'package:deep_pick/deep_pick.dart';

extension type RollWidth(int value) {
  dynamic toJson() => value;

  factory RollWidth.fromPick(Pick pick) => RollWidth(pick.asIntOrThrow());
}
