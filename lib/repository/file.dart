import 'dart:convert';
import 'dart:io';

import 'package:deep_pick/deep_pick.dart';
import 'package:path_provider/path_provider.dart';
import 'package:slitter_app/model/packing_form.dart';
import 'package:slitter_app/model/roll_material.dart';
import 'package:slitter_app/model/roll_width.dart';
import 'package:slitter_app/service/log.dart';
import 'package:path/path.dart' as p;

Future<String> _rollMaterialsFilePath() async {
  final directory = await getApplicationSupportDirectory();
  final filePath = p.join(directory.path, 'roll_materials.json');
  return filePath;
}

Future<void> saveRollMaterials(List<RollMaterial> materials) async {
  final filePath = await _rollMaterialsFilePath();
  final file = File(filePath);
  final json = jsonEncode(materials);
  try {
    await file.writeAsString(json);
  } catch (e) {
    talker.error(e);
    throw Exception('Failled to save roll materials to file');
  }
}

Future<List<RollMaterial>> loadRollMaterials() async {
  final filePath = await _rollMaterialsFilePath();
  final file = File(filePath);

  if (!(await file.exists())) {
    talker.warning('Roll materials file is not found');
    return [];
  }

  try {
    final contents = await file.readAsString();
    final json = jsonDecode(contents);
    final result = pick(json).asListOrThrow(RollMaterial.fromPick);
    return result;
  } catch (e) {
    talker.error(e);
    throw Exception('Failled to load roll materials from file');
  }
}

Future<String> _packingFormsFilePath() async {
  final directory = await getApplicationSupportDirectory();
  final filePath = p.join(directory.path, 'packing_forms.json');
  return filePath;
}

Future<void> savePackingForms(List<PackingForm> packingForms) async {
  final filePath = await _packingFormsFilePath();
  final file = File(filePath);
  final json = jsonEncode(packingForms);
  try {
    await file.writeAsString(json);
  } catch (e) {
    talker.error(e);
    throw Exception('Failled to save packing forms to file');
  }
}

Future<List<PackingForm>> loadPackingForms() async {
  final filePath = await _packingFormsFilePath();
  final file = File(filePath);

  if (!(await file.exists())) {
    talker.warning('Packing forms file is not found');
    return [];
  }

  try {
    final contents = await file.readAsString();
    final json = jsonDecode(contents);
    final result = pick(json).asListOrThrow(PackingForm.fromPick);
    return result;
  } catch (e) {
    talker.error(e);
    throw Exception('Failled to load packing forms from file');
  }
}

Future<String> _rollWidthsFilePath() async {
  final directory = await getApplicationSupportDirectory();
  final filePath = p.join(directory.path, 'roll_widths.json');
  return filePath;
}

Future<void> saveRollWidths(List<RollWidth> rollWidths) async {
  final filePath = await _rollWidthsFilePath();
  final file = File(filePath);
  final json = jsonEncode(rollWidths);
  try {
    await file.writeAsString(json);
  } catch (e) {
    talker.error(e);
    throw Exception('Failled to save roll widths to file');
  }
}

Future<List<RollWidth>> loadRollWidths() async {
  final filePath = await _rollWidthsFilePath();
  final file = File(filePath);

  if (!(await file.exists())) {
    talker.warning('Roll widths file is not found');
    return [];
  }

  try {
    final contents = await file.readAsString();
    final json = jsonDecode(contents);
    final result = pick(json).asListOrThrow(RollWidth.fromPick);
    return result;
  } catch (e) {
    talker.error(e);
    throw Exception('Failled to load roll widths from file');
  }
}
