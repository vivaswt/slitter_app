import 'dart:convert';

import 'package:slitter_app/model/roll_material.dart';
import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';
import 'package:slitter_app/model/packing_form.dart';
import 'package:slitter_app/model/roll_width.dart';
import 'package:slitter_app/service/setting_service.dart';

Future<List<RollMaterial>> fetchMaterials([String? startCursor]) async {
  final url = Uri.parse(
      'https://api.notion.com/v1/data_sources/a09b3d76bdb04d859e02c502c989276e/query');
  final apiKey = await SettingsService().getNotionApiKey();
  final headers = {
    'Notion-Version': '2025-09-03',
    'Authorization': apiKey,
    'Content-Type': 'application/json',
  };
  final Map<String, dynamic> body = {
    'sorts': [
      {'property': '品名', 'direction': 'ascending'}
    ]
  };
  if (startCursor != null) {
    body['start_cursor'] = startCursor;
  }

  final result = await http.post(url, headers: headers, body: jsonEncode(body));

  if (result.statusCode != 200) {
    throw Exception('Failed to load materials');
  }

  final json = jsonDecode(result.body);
  final materials = pick(json, 'results').asListOrThrow(_materialFromPick);
  final hasMore = pick(json, 'has_more').asBoolOrThrow();
  final nextCursor = pick(json, 'next_cursor').asStringOrNull();

  return [...materials, if (hasMore) ...await fetchMaterials(nextCursor)];
}

RollMaterial _materialFromPick(Pick page) =>
    page('properties').letOrThrow((props) => RollMaterial(
        name: props('品名', 'title', 0, 'plain_text').asStringOrThrow(),
        grammage: props('米坪', 'number').asDoubleOrNull(),
        productCode: props('製品コード').letOrThrow(_richTextFromPick)));

String? _richTextFromPick(Pick prop) {
  final plainTexts = prop('rich_text')
      .asListOrThrow((rt) => rt('plain_text').asStringOrThrow())
      .join();
  return plainTexts.isEmpty ? null : plainTexts;
}

Future<List<PackingForm>> fetchPackingForms() async {
  final url = Uri.parse(
      'https://api.notion.com/v1/data_sources/2da606831b2d80ef824d000bc5d59faa/query');
  final apiKey = await SettingsService().getNotionApiKey();
  final headers = {
    'Notion-Version': '2025-09-03',
    'Authorization': apiKey,
    'Content-Type': 'application/json',
  };
  final body = {
    'sorts': [
      {
        'property': '表示順',
        'direction': 'ascending',
      }
    ]
  };
  final result = await http.post(url, headers: headers, body: jsonEncode(body));

  if (result.statusCode != 200) {
    throw Exception('Failed to load packing forms');
  }

  final json = jsonDecode(result.body);
  final forms = pick(json, 'results').asListOrThrow(_packingFormFromPick);

  return forms;
}

PackingForm _packingFormFromPick(Pick page) =>
    page('properties').letOrThrow((props) => PackingForm(
        name: props('表示名', 'title', 0, 'plain_text').asStringOrThrow(),
        order: props('表示順', 'number').asIntOrThrow()));

Future<List<RollWidth>> fetchRollWidths() async {
  final url = Uri.parse(
      'https://api.notion.com/v1/data_sources/2da606831b2d8000b8c5000b6e226133/query');
  final apiKey = await SettingsService().getNotionApiKey();
  final headers = {
    'Notion-Version': '2025-09-03',
    'Authorization': apiKey,
    'Content-Type': 'application/json',
  };
  final result = await http.post(url, headers: headers);

  if (result.statusCode != 200) {
    throw Exception('Failed to load roll widths');
  }

  final json = jsonDecode(result.body);
  final widths = pick(json, 'results').asListOrThrow(_rollWidthFromPick);

  return widths..sort((a, b) => a.value.compareTo(b.value));
}

RollWidth _rollWidthFromPick(Pick page) =>
    page('properties').letOrThrow((props) => RollWidth(
        int.parse(props('巾', 'title', 0, 'plain_text').asStringOrThrow())));
