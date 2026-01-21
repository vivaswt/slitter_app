import 'package:flutter/material.dart';
import 'package:slitter_app/api/notion.dart';
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
  final _formKey = GlobalKey<FormState>();

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
      appBar: MiniLabelPrintAppBar(onPrint: _showMiniLabels),
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
                  ].wrapWithColumn(spacing: 8).wrapWithForm(key: _formKey);
                }

                if (snapshot.hasError) {
                  return Text('error: ${snapshot.error}');
                }

                return const SizedBox(
                    width: 60, height: 60, child: CircularProgressIndicator());
              })
          .wrapWithPadding(
              padding: const EdgeInsetsGeometry.fromLTRB(16, 16, 16, 80)),
      floatingActionButton: AddNewLineButton(labelRequest: _labelRequest));

  @override
  void dispose() {
    _labelRequest.dispose();
    super.dispose();
  }

  Future<void> _showMiniLabels() async {
    if (_labelRequest.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('印刷するラベルがありません。')),
      );

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final printJob = createPrintJob(_baseNumber.value, _labelRequest);

    await showMiniLabels(_baseNumber.value, printJob);
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

class DeleteLineButton extends StatelessWidget {
  final VoidCallback onDelete;

  const DeleteLineButton({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) => IconButton(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline),
      tooltip: '行削除');
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
                onDelete: () =>
                    labelRequest.removeItem(labelRequest.items[index]),
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

class MiniLabelPrintItem extends StatefulWidget {
  final RequestItem item;
  final List<RollMaterial> rollMaterials;
  final List<RollWidth> rollWidths;
  final List<PackingForm> packingForms;
  final VoidCallback onDelete;

  const MiniLabelPrintItem(
      {super.key,
      required this.item,
      required this.onDelete,
      required this.rollMaterials,
      required this.rollWidths,
      required this.packingForms});

  @override
  State<MiniLabelPrintItem> createState() => _MiniLabelPrintItemState();
}

class _MiniLabelPrintItemState extends State<MiniLabelPrintItem> {
  final _isHovering = ValueNotifier(false);

  @override
  void dispose() {
    _isHovering.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => <Widget>[
        RollMaterialDropDownMenu(
            rollMaterials: widget.rollMaterials, item: widget.item),
        RollWidthDropDownMenu(rollWidths: widget.rollWidths, item: widget.item),
        PackingFormDropDownMenu(
            packingForms: widget.packingForms, item: widget.item),
        PrintCountDropDownMenu(item: widget.item),
        const Spacer(),
        ValueListenableBuilder(
          valueListenable: _isHovering,
          builder: (context, value, child) => value
              ? DeleteLineButton(onDelete: widget.onDelete)
              : const SizedBox.shrink(),
        ),
      ].wrapWithRow(spacing: 4).wrapWithMouseRegion(
          hitTestBehavior: HitTestBehavior.opaque,
          onEnter: (_) => _isHovering.value = true,
          onExit: (_) => _isHovering.value = false);
}

class BaseNumberTextField extends StatelessWidget {
  final ValueNotifier<String> _baseNumber;

  const BaseNumberTextField(
      {super.key, required ValueNotifier<String> baseNumber})
      : _baseNumber = baseNumber;

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: _baseNumber.value,
        validator: _validator,
        decoration: const InputDecoration(labelText: '製品ロール№'),
        onChanged: (value) => _baseNumber.value = value,
      );

  String? _validator(String? value) {
    if (value == null || value.isEmpty) {
      return '製品ロール№を入力してください';
    }
    return null;
  }
  //switch (value) { null || '' => '製品ロール№を入力してください', _ => null };
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

    return DropdownMenuFormField<RollMaterial?>(
      //label: const Text('品名'),
      initialSelection: item.material,
      validator: _validator,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.material = value,
    );
  }

  String? _validator(RollMaterial? value) {
    if (value == null) {
      return '品名を選択してください';
    }
    return null;
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

    return DropdownMenuFormField<RollWidth?>(
      //label: const Text('巾'),
      initialSelection: item.width,
      validator: _validator,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.width = value,
      textAlign: TextAlign.right,
    );
  }

  String? _validator(RollWidth? value) {
    if (value == null) {
      return '巾を選択してください';
    }
    return null;
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

    return DropdownMenuFormField<PackingForm?>(
      //label: const Text('角当て'),
      initialSelection: item.packingForm,
      validator: _validator,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.packingForm = value,
    );
  }

  String? _validator(PackingForm? value) {
    if (value == null) {
      return '包装形態を選択してください';
    }
    return null;
  }
}

class PrintCountDropDownMenu extends StatelessWidget {
  final RequestItem item;

  const PrintCountDropDownMenu({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final entries = List.generate(
        20, (i) => DropdownMenuEntry(value: i + 1, label: '${i + 1}枚'));

    return DropdownMenuFormField<int?>(
      //label: const Text('枚数'),
      initialSelection: item.printCount,
      validator: _validator,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.printCount = value,
    );
  }

  String? _validator(int? value) {
    if (value == null) {
      return '印刷枚数を選択してください';
    }
    return null;
  }
}
