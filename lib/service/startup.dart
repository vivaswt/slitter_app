import 'package:slitter_app/repository/file.dart';
import 'package:slitter_app/repository/notion.dart';
import 'package:slitter_app/service/log.dart';

class StartupService {
  static bool _initialized = false;
  static Future<void> run() async {
    if (_initialized) return;

    _initialized = true;
    await _syncRollMaterials();
    await _syncRollWidths();
    await _syncPackingForms();
  }
}

Future<void> _syncRollMaterials() async {
  try {
    final materials = await fetchMaterials();
    await saveRollMaterials(materials);
    talker.info('Roll materials synced');
  } catch (_) {}
}

Future<void> _syncRollWidths() async {
  try {
    final rollWidths = await fetchRollWidths();
    await saveRollWidths(rollWidths);
    talker.info('Roll widths synced');
  } catch (_) {}
}

Future<void> _syncPackingForms() async {
  try {
    final packingForms = await fetchPackingForms();
    await savePackingForms(packingForms);
    talker.info('Packing forms synced');
  } catch (_) {}
}
