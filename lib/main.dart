import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';

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
