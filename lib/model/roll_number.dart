extension type RollBaseNumber(String value) {
  static const _monthChar = "1234567890AB";

  factory RollBaseNumber.fromDate(DateTime date) {
    final y = date.year % 10;
    final m = _monthChar[date.month - 1];
    final d = date.day.toString().padLeft(2, '0');
    return RollBaseNumber('8$y$m${d}96');
  }
}

extension type RollSequenceNumber(int value) {}

class RollNumber {
  final RollBaseNumber baseNumber;
  final RollSequenceNumber sequenceNumber;

  const RollNumber({required this.baseNumber, required this.sequenceNumber});
}
