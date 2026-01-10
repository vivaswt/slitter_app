import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:slitter_app/model/mini_label_request.dart';
import 'package:slitter_app/report/pdf_report.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

const _sizes = (page: Size(728.490, 515.9052), label: Size(164.0, 143.28));
const _offsets =
    (firstLabel: Offset(32.0, 40.0), packingForm: Offset(0.0, 120.0));

const _pageWidth = 728.490;
const _pageHeight = 515.9052;
const _baseFontSize = 9.0;

typedef _LayoutConfig = ({
  Size page,
  ElementLayout label,
});

typedef _LabelLayoutConfig = ({
  TextElementLayout productName,
  TextElementLayout productWidth,
  TextElementLayout baseNumber,
  TextElementLayout packingForm,
});

const _LayoutConfig _layoutConfig = (
  page: Size(_pageWidth, _pageHeight),
  label: (
    offset: Offset(32.0, 40.0),
    size: Size(164.0, 143.28),
  ),
);

const _LabelLayoutConfig _labelLayoutConfig = (
  productName: (
    offset: Offset(0.0, 50.0),
    size: Size(_pageWidth, 0.0),
    alignment: Alignment.center,
    fontSize: _baseFontSize
  ),
  productWidth: (
    offset: Offset(52.0, 71.0),
    size: Size(30, 0.0),
    alignment: Alignment.right,
    fontSize: _baseFontSize
  ),
  baseNumber: (
    offset: Offset(76.0, 89.0),
    size: Size(30, 0.0),
    alignment: Alignment.left,
    fontSize: _baseFontSize
  ),
  packingForm: (
    offset: Offset(0.0, 120.0),
    size: Size(_pageWidth, 0.0),
    alignment: Alignment.center,
    fontSize: _baseFontSize
  ),
);

Future<void> showMiniLabels(String baseNumber, LabelRequest request) async {
  PdfTemplate template = await _getTemplate();

  final document = PdfDocument();
  document.pageSettings.setMargins(0);
  document.pageSettings.size = _sizes.page;
  document.pageSettings.orientation = PdfPageOrientation.landscape;
  final font = PdfCjkStandardFont(PdfCjkFontFamily.heiseiKakuGothicW5, 9);

  final page = document.pages.add();
  page.graphics.drawPdfTemplate(template, const Offset(0, 0));

  final drawString = _createStringDrawer(page.graphics, font);
  final drawCenterString = _createStringCenterDrawer(page.graphics, font);

  final productName = request.items[0].material!.name;
  final packingForm = request.items.first.packingForm!.name;

  //drawCenterString(productName, (114, 50));
  drawCenterString(
      productName, (_offsets.firstLabel.dx + _sizes.label.width / 2, 50));
  drawString(baseNumber, (76, 89));
  drawString(request.items[0].width?.value.toString() ?? '', (52, 71));
  drawCenterString(packingForm, (
    _offsets.firstLabel.dx + _offsets.packingForm.dx + _sizes.label.width / 2,
    _offsets.firstLabel.dy + _offsets.packingForm.dy,
  ));

  // page.graphics.drawRectangle(
  //     brush: PdfSolidBrush(PdfColor(0, 0, 0)),
  //     bounds: const Rect.fromLTWH(32, 40, 164, 143.28));

  final filePath = await _reportFilePath();
  final outputFile = File(filePath);

  outputFile.writeAsBytes(await document.save());
  document.dispose();

  await OpenFile.open(filePath);
}

void drawString(PdfGraphics graphics, String string, TextElementLayout layout,
    {Offset baseOffset = const Offset(0.0, 0.0)}) {
  final font =
      PdfCjkStandardFont(PdfCjkFontFamily.heiseiKakuGothicW5, layout.fontSize);
  final stringSize = font.measureString(string);
  final absOffset = baseOffset + layout.offset;

  final bounds = switch (layout.alignment) {
    Alignment.left => Rect.fromLTWH(
        absOffset.dx, absOffset.dy, layout.size.width, layout.size.height),
    Alignment.center => Rect.fromCenter(
        center: absOffset + Offset(stringSize.width / 2, stringSize.height / 2),
        width: stringSize.width,
        height: stringSize.height),
    Alignment.right => Rect.fromLTWH(
        absOffset.dx + layout.size.width - stringSize.width,
        absOffset.dy,
        stringSize.width,
        layout.size.height)
  };
}

void Function(String string, (double, double)) _createStringDrawer(
        PdfGraphics graphics, PdfCjkStandardFont font) =>
    (string, postion) => graphics.drawString(
          string,
          font,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(postion.$1, postion.$2, _sizes.page.width, 0),
        );

void Function(String string, (double, double)) _createStringCenterDrawer(
        PdfGraphics graphics, PdfCjkStandardFont font) =>
    (string, postion) {
      final size = font.measureString(string);
      graphics.drawString(string, font,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromCenter(
              center: Offset(postion.$1, postion.$2 + size.height / 2),
              width: size.width,
              height: 0));
    };

Future<PdfTemplate> _getTemplate() async {
  final inputBytes = await rootBundle
      .load('assets/pdf_templates/mini_label.pdf')
      .then((byteData) => byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  final template =
      PdfDocument(inputBytes: inputBytes).pages[0].createTemplate();
  return template;
}

String _reportFileName() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyyMMddHHmmss');
  return 'minilabel_${formatter.format(now)}.pdf';
}

Future<String> _reportFilePath() async {
  final tempDirectory = await getTemporaryDirectory();
  final fileName = _reportFileName();
  return p.join(tempDirectory.path, fileName);
}
