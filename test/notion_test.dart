import 'package:flutter_test/flutter_test.dart';
import 'package:slitter_app/api/notion.dart';

void main() {
  group('normal', () {
    test('normal', () async {
      final result = await fetchMaterials();
      expect(result.length, greaterThan(100));
    });

    test('packing forms', () async {
      final result = await fetchPackingForms();
      expect(result.length, 4);
      expect(result.map((r) => r.order),
          orderedEquals(Iterable.generate(4, (i) => i + 1)));
    });

    test('roll widths', () async {
      final result = await fetchRollWidths();
      expect(result.length, 10);
    });
  });
}
