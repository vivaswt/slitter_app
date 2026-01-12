import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:slitter_app/extension/fp_iterable.dart';
import 'package:slitter_app/model/packing_form.dart';
import 'package:slitter_app/model/roll_material.dart';
import 'package:slitter_app/model/roll_width.dart';
import 'package:slitter_app/report/pdf_report.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

const _pageWidth = 728.490;
const _pageHeight = 515.9052;
const _labelWidth = 164.0;
const _baseFontSize = 9.0;

typedef MiniLabelPrintJob = ({
  String baseNumber,
  List<MiniLabelPrintJobItem> items,
});

typedef MiniLabelPrintJobItem = ({
  RollMaterial material,
  RollWidth width,
  PackingForm packingForm,
  int printCount,
});

typedef _LayoutConfig = ({
  Size page,
  ElementLayout label,
});

typedef _LabelLayoutConfig = ({
  TextElementLayout productName,
  TextElementLayout productWidth,
  TextElementLayout baseNumber,
  TextElementLayout packingForm,
  int countOfLabelsPerPage,
  int rowsPerPage,
  int columnsPerPage,
});

const _LayoutConfig _layoutConfig = (
  page: Size(_pageWidth, _pageHeight),
  label: (
    offset: Offset(32.0, 40.0),
    size: Size(_labelWidth, 145.20),
  ),
);

const _LabelLayoutConfig _labelLayoutConfig = (
  productName: (
    offset: Offset(0.0, 10.0),
    size: Size(_labelWidth, 0.0),
    alignment: Alignment.center,
    fontSize: _baseFontSize
  ),
  productWidth: (
    offset: Offset(20.0, 31.0),
    size: Size(20, 0.0),
    alignment: Alignment.right,
    fontSize: _baseFontSize
  ),
  baseNumber: (
    offset: Offset(52.0, 49.0),
    size: Size(32, 0.0),
    alignment: Alignment.left,
    fontSize: _baseFontSize
  ),
  packingForm: (
    offset: Offset(0.0, 122.0),
    size: Size(_labelWidth, 0.0),
    alignment: Alignment.center,
    fontSize: _baseFontSize
  ),
  countOfLabelsPerPage: 8,
  rowsPerPage: 2,
  columnsPerPage: 4,
);

Future<void> showMiniLabels(String baseNumber, MiniLabelPrintJob job) async {
  final document = _createDocumentWithSetting();
  await _renderLabels(job, document);

  final filePath = await _reportFilePath();
  final outputFile = File(filePath);

  final outputBytes = await document.save();
  await outputFile.writeAsBytes(outputBytes);

  document.dispose();

  await OpenFile.open(filePath);
}

PdfDocument _createDocumentWithSetting() {
  final document = PdfDocument();
  document.pageSettings.setMargins(0);
  document.pageSettings.size = _layoutConfig.page;
  document.pageSettings.orientation = PdfPageOrientation.landscape;
  return document;
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
        center:
            absOffset + Offset(layout.size.width / 2, stringSize.height / 2),
        width: stringSize.width,
        height: stringSize.height),
    Alignment.right => Rect.fromLTWH(
        absOffset.dx + layout.size.width - stringSize.width,
        absOffset.dy,
        stringSize.width,
        layout.size.height)
  };

  graphics.drawString(string, font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)), bounds: bounds);
}

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

typedef _LabelPosition = ({PdfPage page, Offset offset});

Future<Iterable<_LabelPosition>> _allLabelOffsets(
    PdfDocument document, int countOfPages) async {
  final pages = await _addPages(document, countOfPages);
  final offsets = _labelOffsetsInPage();
  final positions = pages
      .expand((page) => offsets.map((offset) => (page: page, offset: offset)));

  return positions;
}

Future<Iterable<PdfPage>> _addPages(
    PdfDocument document, int countOfPages) async {
  PdfTemplate template = await _getTemplate();

  final pages = Iterable.generate(countOfPages, (_) {
    final page = document.pages.add();
    page.graphics.drawPdfTemplate(template, Offset.zero);
    return page;
  });

  return pages;
}

Iterable<Offset> _labelOffsetsInPage() =>
    Iterable.generate(_labelLayoutConfig.countOfLabelsPerPage, (i) {
      final offset = Offset(
          _layoutConfig.label.size.width *
              (i % _labelLayoutConfig.columnsPerPage),
          _layoutConfig.label.size.height *
              (i ~/ _labelLayoutConfig.columnsPerPage));
      return _layoutConfig.label.offset + offset;
    });

typedef _LabelElements = ({
  String productName,
  int productWidth,
  String baseNumber,
  String packingForm,
});

void _drawLabel(_LabelElements elements, _LabelPosition position) {
  void draw(String string, TextElementLayout layout) =>
      drawString(position.page.graphics, string, layout,
          baseOffset: position.offset);

  draw(elements.productName, _labelLayoutConfig.productName);
  draw(elements.baseNumber, _labelLayoutConfig.baseNumber);
  draw(elements.productWidth.toString(), _labelLayoutConfig.productWidth);
  draw(elements.packingForm, _labelLayoutConfig.packingForm);
}

Iterable<_LabelElements> _labelData(MiniLabelPrintJob job) {
  _LabelElements toElements(MiniLabelPrintJobItem item) => (
        productName: item.material.name,
        productWidth: item.width.value,
        baseNumber: job.baseNumber,
        packingForm: item.packingForm.name
      );

  final elementss = job.items.expand((jobItem) =>
      Iterable.generate(jobItem.printCount, (_) => toElements(jobItem)));

  return elementss;
}

Future<void> _renderLabels(MiniLabelPrintJob job, PdfDocument document) async {
  final labelData = _labelData(job);
  final countOfPages = _countOfPagesFromPrintJob(job);
  final labelOffsets = await _allLabelOffsets(document, countOfPages);

  // zipWith returns an Iterable, so it is not executed until it is iterated.
  // Therefore, toList() is called to execute the drawing.
  labelData
      .zipWith(labelOffsets, (elements, offset) => _drawLabel(elements, offset))
      .toList();
}

int _countOfPagesFromPrintJob(MiniLabelPrintJob job) {
  final countOfLabels = job.items
      .map((item) => item.printCount)
      .fold(0, (value, element) => value + element);
  final countOfPages =
      (countOfLabels / _labelLayoutConfig.countOfLabelsPerPage).ceil();
  return countOfPages;
}
