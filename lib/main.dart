import 'dart:collection' show UnmodifiableListView;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:slitter_app/master_data.dart'
    show getMaterials, getWidths, getPackagings;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => ChangeNotifierProvider(
              create: (context) => InputModel(),
              child: Column(
                children: [
                  Consumer<InputModel>(
                      builder: (context, input, child) => TextFormField(
                          initialValue: input.material,
                          onChanged: (value) => input.material = value)),
                  Consumer<InputModel>(
                      builder: (context, input, child) => ElevatedButton(
                            onPressed: () =>
                                handleButtonPress(context, input.material),
                            child: const Text('PDF'),
                          ))
                ],
              )),
        ),
      ),
    );
  }

  Future<void> handleButtonPress(BuildContext context, String text) async {
    final outputFile = File('example.pdf');
    if (outputFile.existsSync()) {
      try {
        outputFile.deleteSync();
      } catch (e) {
        // Show SnackBar and return if file can't be deleted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('close the output file')),
        );
        return;
      }
    }

    final template =
        PdfDocument(inputBytes: File('mini_label.pdf').readAsBytesSync())
            .pages[0]
            .createTemplate();

    final document = PdfDocument();
    document.pageSettings.setMargins(0);
    document.pageSettings.size = const Size(728.490, 515.9052);
    document.pageSettings.orientation = PdfPageOrientation.landscape;

    final font = PdfCjkStandardFont(PdfCjkFontFamily.heiseiKakuGothicW5, 12);
    final page = document.pages.add();

    page.graphics.drawPdfTemplate(template, const Offset(0, 0));

    final Size sizeOfText = font.measureString(text);

    page.graphics.drawString(text, font,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(0, 0, sizeOfText.width, sizeOfText.height));
    outputFile.writeAsBytes(await document.save());
    document.dispose();

    await OpenFile.open('example.pdf');
  }
}

class InputModel extends ChangeNotifier {
  String _material = "";

  String get material => _material;
  set material(String value) {
    _material = value;
    notifyListeners();
  }
}

class LabelListScreen extends StatelessWidget {
  const LabelListScreen({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<LabelRequests>(
      create: (_) => LabelRequests(),
      child: Builder(
          builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('ミニラベル印刷'),
              ),
              body: const LabelRequestTable(),
              floatingActionButton: addButton(context))));

  Widget addButton(BuildContext context) => FloatingActionButton(
        onPressed: () {
          final request = LabelRequest(
              material: 'SP-8Kアオ(HGN7)',
              width: 1000,
              packaging: 'なし',
              printCount: 1);
          context.read<LabelRequests>().add(request);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<LabelRequest>.value(
                        value: request,
                        child: const LabelDetailScreen(),
                      )));
        },
        child: const Icon(Icons.add),
      );
}

class LabelRequestTable extends StatelessWidget {
  const LabelRequestTable({super.key});

  @override
  Widget build(BuildContext context) => DataTable(
        columns: columns(),
        rows: rows(context),
        showCheckboxColumn: false,
      );

  List<DataColumn> columns() => ['品名', '巾', '包装', '枚数']
      .map((title) => DataColumn(label: Text(title)))
      .toList();

  List<DataRow> rows(BuildContext context) {
    final requests = context.watch<LabelRequests>();
    return requests.requests.map((r) => toRow(context, r)).toList();
  }

  DataRow toRow(BuildContext context, LabelRequest r) => DataRow(
          cells: [
            DataCell(Text(r.material)),
            DataCell(Text(r.width.toString())),
            DataCell(Text(r.packaging)),
            DataCell(Text(r.printCount.toString()))
          ],
          onSelectChanged: (selected) {
            if (selected == null || !selected) return;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider<LabelRequest>.value(
                          value: r,
                          child: const LabelDetailScreen(),
                        )));
          });
}

class LabelDetailScreen extends StatelessWidget {
  const LabelDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('ミニラベル詳細'),
        ),
        body: Consumer<LabelRequest>(builder: (context, request, child) {
          return dataColumn(context);
        }),
      );

  Widget dataColumn(BuildContext context) => Column(
        children: [
          const Row(children: [
            Text('品名: '),
            MaterialDropdownMenu(),
          ]),
          const Row(children: [
            Text('巾: '),
            WidthDropdownMenu(),
          ]),
          const Row(children: [
            Text('包装: '),
            PackagingDroDownMenu(),
          ]),
          const Row(children: [
            Text('枚数: '),
            PrintCountDropdownMenu(),
          ]),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'))
        ],
      );
}

class MaterialDropdownMenu extends StatelessWidget {
  const MaterialDropdownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<LabelRequest>();

    return DropdownMenu(
      initialSelection: request.material,
      requestFocusOnTap: false,
      dropdownMenuEntries: materialEntries(),
      onSelected: (value) {
        if (value == null) return;
        request.material = value;
      },
    );
  }

  List<DropdownMenuEntry<String>> materialEntries() => getMaterials()
      .map((m) => DropdownMenuEntry(value: m.name, label: m.name))
      .toList();
}

class WidthDropdownMenu extends StatelessWidget {
  const WidthDropdownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<LabelRequest>();

    return DropdownMenu(
      initialSelection: request.width,
      requestFocusOnTap: false,
      label: const Text('巾'),
      dropdownMenuEntries: widthEntries(),
      onSelected: (value) {
        if (value == null) return;
        request.width = value;
      },
    );
  }

  List<DropdownMenuEntry<int>> widthEntries() => getWidths()
      .map((w) => DropdownMenuEntry(value: w, label: '$w巾'))
      .toList();
}

class PrintCountDropdownMenu extends StatelessWidget {
  const PrintCountDropdownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<LabelRequest>();

    return DropdownMenu(
      initialSelection: request.printCount,
      requestFocusOnTap: false,
      dropdownMenuEntries: printCountEntries(),
      onSelected: (value) {
        if (value == null) return;
        request.printCount = value;
      },
    );
  }

  List<DropdownMenuEntry<int>> printCountEntries() => List.generate(
      8, (i) => DropdownMenuEntry(value: i + 1, label: '${i + 1}枚'));
}

class PackagingDroDownMenu extends StatelessWidget {
  const PackagingDroDownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<LabelRequest>();

    return DropdownMenu(
      initialSelection: request.packaging,
      requestFocusOnTap: false,
      dropdownMenuEntries: packagingEntries(),
      onSelected: (value) {
        if (value == null) return;
        request.packaging = value;
      },
    );
  }

  List<DropdownMenuEntry<String>> packagingEntries() => getPackagings()
      .map((p) => DropdownMenuEntry(value: p, label: p))
      .toList();
}

class LabelRequest extends ChangeNotifier {
  String _material;
  int _width;
  String _packaging;
  int _printCount;

  LabelRequest(
      {required String material,
      required int width,
      required String packaging,
      required int printCount})
      : _width = width,
        _material = material,
        _packaging = packaging,
        _printCount = printCount;

  String get material => _material;
  set material(String value) {
    _material = value;
    notifyListeners();
  }

  int get width => _width;
  set width(int value) {
    _width = value;
    notifyListeners();
  }

  String get packaging => _packaging;
  set packaging(String value) {
    _packaging = value;
    notifyListeners();
  }

  int get printCount => _printCount;
  set printCount(int value) {
    _printCount = value;
    notifyListeners();
  }
}

class LabelRequests extends ChangeNotifier {
  final List<LabelRequest> _requests = [
    LabelRequest(
        material: 'SP-G63シロA(HGN8)',
        width: 1000,
        packaging: 'なし',
        printCount: 5),
    LabelRequest(
        material: 'SP-8Kアオ(HGN7)WT4(12.2R)',
        width: 1120,
        packaging: '角当て(大)',
        printCount: 1),
    LabelRequest(
        material: 'SP-9Kアサギ(HGN45)(3％)',
        width: 1040,
        packaging: '角当て(小)',
        printCount: 8)
  ];

  LabelRequests() {
    for (final r in _requests) {
      r.addListener(onItemUpdated);
    }
  }

  UnmodifiableListView<LabelRequest> get requests =>
      UnmodifiableListView(_requests);

  void add(LabelRequest request) {
    request.addListener(onItemUpdated);
    _requests.add(request);
    notifyListeners();
  }

  void remove(LabelRequest request) {
    request.removeListener(onItemUpdated);
    _requests.remove(request);
    notifyListeners();
  }

  void clear() {
    for (final r in _requests) {
      r.removeListener(onItemUpdated);
    }
    _requests.clear();
    notifyListeners();
  }

  void onItemUpdated() => notifyListeners();

  @override
  void dispose() {
    for (final r in _requests) {
      r.removeListener(onItemUpdated);
    }
    super.dispose();
  }
}
