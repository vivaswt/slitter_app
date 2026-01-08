import 'dart:io';

import 'package:flutter/material.dart';
import 'package:slitter_app/screen/mini_label_print.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: MiniLabelPrint());

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

class MaterialDropDownMenu extends StatelessWidget {
  static const _materials = ['SP-8LKアオ(HGN11A)', 'SP-8Kアオ(HGN7)', 'SP-8Eアイボリー'];

  const MaterialDropDownMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final entries =
        _materials.map((m) => DropdownMenuEntry(value: m, label: m)).toList();
    return Consumer<InputModel>(builder: (context, value, child) {
      return DropdownMenu(
        label: const Text('品名'),
        initialSelection: null,
        requestFocusOnTap: false,
        dropdownMenuEntries: entries,
        onSelected: (value) => print,
      );
    });
  }
}
