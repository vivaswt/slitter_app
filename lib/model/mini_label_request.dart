import 'package:flutter/material.dart';
import 'package:slitter_app/model/packing_form.dart';
import 'package:slitter_app/model/roll_material.dart';
import 'package:slitter_app/model/roll_width.dart';

class LabelRequest extends ChangeNotifier {
  final List<RequestItem> items = [];

  @override
  void dispose() {
    for (final item in items) {
      item.removeListener(notifyListeners);
      item.dispose();
    }
    super.dispose();
  }

  void addItem(RequestItem item) {
    items.add(item);
    item.addListener(notifyListeners);
    notifyListeners();
  }

  void removeItem(RequestItem item) {
    item.removeListener(notifyListeners);
    items.remove(item);
    notifyListeners();
  }
}

class RequestItem extends ChangeNotifier {
  RollMaterial? _material;
  RollWidth? _width;
  PackingForm? _packingForm;
  int? _printCount;

  RequestItem({
    RollMaterial? material,
    RollWidth? width,
    PackingForm? packingForm,
    int? printCount,
  })  : _material = material,
        _width = width,
        _packingForm = packingForm,
        _printCount = printCount;

  RollMaterial? get material => _material;
  set material(RollMaterial? value) {
    _material = value;
    notifyListeners();
  }

  RollWidth? get width => _width;
  set width(RollWidth? value) {
    _width = value;
    notifyListeners();
  }

  PackingForm? get packingForm => _packingForm;
  set packingForm(PackingForm? value) {
    _packingForm = value;
    notifyListeners();
  }

  int? get printCount => _printCount;
  set printCount(int? value) {
    _printCount = value;
    notifyListeners();
  }
}
