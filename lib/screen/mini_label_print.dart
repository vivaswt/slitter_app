import 'package:flutter/material.dart';
import 'package:slitter_app/api/notion.dart';
import 'package:slitter_app/extension/pipable.dart';
import 'package:slitter_app/model/mini_label_request.dart';
import 'package:slitter_app/model/roll_material.dart';
import 'package:slitter_app/model/packing_form.dart';
import 'package:slitter_app/model/roll_width.dart';
import 'package:slitter_app/extension/widget_wrap.dart';
import 'package:slitter_app/report/mini_label.dart';

class MiniLabelPrint extends StatefulWidget {
  const MiniLabelPrint({super.key});

  @override
  State<StatefulWidget> createState() {
    return MiniLabelPrintState();
  }
}

typedef _FetchedDatas = ({
  List<RollMaterial> rollMaterials,
  List<RollWidth> rollWidths,
  List<PackingForm> packingForms
});

class MiniLabelPrintState extends State<MiniLabelPrint> {
  final ValueNotifier<String> _baseNumber = ValueNotifier('');
  late final LabelRequest _labelRequest;
  final Future<List<RollMaterial>> _rollMaterials = fetchMaterials();
  final Future<List<RollWidth>> _rollWidths = fetchRollWidths();
  final Future<List<PackingForm>> _packingForms = fetchPackingForms();

  @override
  void initState() {
    super.initState();
    _labelRequest = LabelRequest();
    _labelRequest.addItem(RequestItem());
  }

  Future<_FetchedDatas> _fetchAll() async {
    final rollMaterials = await _rollMaterials;
    final rollWidths = await _rollWidths;
    final packingForms = await _packingForms;
    return (
      rollMaterials: rollMaterials,
      rollWidths: rollWidths,
      packingForms: packingForms
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: MiniLabelPrintAppBar(
          onPrint: () => createPrintJob(_baseNumber.value, _labelRequest)
              .pipe((job) => showMiniLabels(_baseNumber.value, job))),
      body: FutureBuilder(
          future: _fetchAll(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final (:rollMaterials, :rollWidths, :packingForms) =
                  snapshot.data!;

              return [
                BaseNumberTextField(baseNumber: _baseNumber),
                MiniLabelPrintList(
                  labelRequest: _labelRequest,
                  rollMaterials: rollMaterials,
                  rollWidths: rollWidths,
                  packingForms: packingForms,
                ).wrapWithExpanded()
              ].wrapWithColumn(spacing: 8);
            }

            if (snapshot.hasError) {
              return Text('error: ${snapshot.error}');
            }

            return const SizedBox(
                width: 60, height: 60, child: CircularProgressIndicator());
          }).wrapWithPadding(padding: const EdgeInsetsGeometry.all(16)),
      floatingActionButton: AddNewLineButton(labelRequest: _labelRequest));

  @override
  void dispose() {
    super.dispose();
    _labelRequest.dispose();
  }
}

MiniLabelPrintJob createPrintJob(String baseNumber, LabelRequest labelRequest) {
  final List<MiniLabelPrintJobItem> items = labelRequest.items
      .map((requestItem) => (
            material: requestItem.material!,
            width: requestItem.width!,
            packingForm: requestItem.packingForm!,
            printCount: requestItem.printCount!
          ))
      .toList();

  return (baseNumber: baseNumber, items: items);
}

class AddNewLineButton extends StatelessWidget {
  const AddNewLineButton({
    super.key,
    required LabelRequest labelRequest,
  }) : _labelRequest = labelRequest;

  final LabelRequest _labelRequest;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _labelRequest.addItem(RequestItem()),
      tooltip: '行追加',
      child: const Icon(Icons.add),
    );
  }
}

class MiniLabelPrintList extends StatelessWidget {
  final LabelRequest labelRequest;
  final List<RollMaterial> rollMaterials;
  final List<RollWidth> rollWidths;
  final List<PackingForm> packingForms;

  const MiniLabelPrintList({
    super.key,
    required this.labelRequest,
    required this.rollMaterials,
    required this.rollWidths,
    required this.packingForms,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: labelRequest,
      builder: (context, child) => ListView.builder(
          itemCount: labelRequest.items.length,
          itemBuilder: (context, index) => MiniLabelPrintItem(
                item: labelRequest.items[index],
                rollMaterials: rollMaterials,
                rollWidths: rollWidths,
                packingForms: packingForms,
              )));
}

class MiniLabelPrintAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final void Function() onPrint;

  const MiniLabelPrintAppBar({super.key, required this.onPrint});

  @override
  Widget build(BuildContext context) => AppBar(
        title: [const Icon(Icons.label), const Text('ミニラベル印刷')].wrapWithRow(),
        actions: [
          IconButton(
            onPressed: onPrint,
            icon: const Icon(Icons.print),
            tooltip: '印刷',
          )
        ],
        actionsPadding: const EdgeInsets.only(right: 24),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MiniLabelPrintItem extends StatelessWidget {
  final RequestItem item;
  final List<RollMaterial> rollMaterials;
  final List<RollWidth> rollWidths;
  final List<PackingForm> packingForms;

  const MiniLabelPrintItem(
      {super.key,
      required this.item,
      required this.rollMaterials,
      required this.rollWidths,
      required this.packingForms});

  @override
  Widget build(BuildContext context) => <Widget>[
        RollMaterialDropDownMenu(rollMaterials: rollMaterials, item: item),
        RollWidthDropDownMenu(rollWidths: rollWidths, item: item),
        PackingFormDropDownMenu(packingForms: packingForms, item: item),
        PrintCountDropDownMenu(item: item),
      ].wrapWithRow(spacing: 4);
}

class BaseNumberTextField extends StatelessWidget {
  final ValueNotifier<String> _baseNumber;

  const BaseNumberTextField(
      {super.key, required ValueNotifier<String> baseNumber})
      : _baseNumber = baseNumber;

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: _baseNumber.value,
        decoration: const InputDecoration(labelText: '製品ロール№'),
        onChanged: (value) => _baseNumber.value = value,
      );
}

class RollMaterialDropDownMenu extends StatelessWidget {
  final List<RollMaterial> rollMaterials;
  final RequestItem item;

  const RollMaterialDropDownMenu(
      {super.key, required this.rollMaterials, required this.item});

  @override
  Widget build(BuildContext context) {
    final entries = rollMaterials
        .map((m) => DropdownMenuEntry(value: m, label: m.name))
        .toList();

    return DropdownMenu<RollMaterial?>(
      //label: const Text('品名'),
      initialSelection: item.material,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.material = value,
    );
  }
}

class RollWidthDropDownMenu extends StatelessWidget {
  final List<RollWidth> rollWidths;
  final RequestItem item;

  const RollWidthDropDownMenu(
      {super.key, required this.rollWidths, required this.item});

  @override
  Widget build(BuildContext context) {
    final entries = rollWidths
        .map((w) => DropdownMenuEntry(
            value: w,
            label: w.value.toString(),
            labelWidget: Text(
              w.value.toString(),
              textAlign: TextAlign.right,
            )))
        .toList();

    return DropdownMenu<RollWidth?>(
      //label: const Text('巾'),
      initialSelection: item.width,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.width = value,
      textAlign: TextAlign.right,
    );
  }
}

class PackingFormDropDownMenu extends StatelessWidget {
  final List<PackingForm> packingForms;
  final RequestItem item;

  const PackingFormDropDownMenu(
      {super.key, required this.packingForms, required this.item});

  @override
  Widget build(BuildContext context) {
    final entries = packingForms
        .map((pf) => DropdownMenuEntry(value: pf, label: pf.name))
        .toList();

    return DropdownMenu<PackingForm?>(
      //label: const Text('角当て'),
      initialSelection: item.packingForm,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.packingForm = value,
    );
  }
}

class PrintCountDropDownMenu extends StatelessWidget {
  final RequestItem item;

  const PrintCountDropDownMenu({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final entries = List.generate(
        20, (i) => DropdownMenuEntry(value: i + 1, label: '${i + 1}枚'));

    return DropdownMenu<int?>(
      //label: const Text('枚数'),
      initialSelection: item.printCount,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.printCount = value,
    );
  }
}
