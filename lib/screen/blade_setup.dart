import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:slitter_app/extension/widget_wrap.dart';
import 'package:slitter_app/screen/main_drawer.dart';

class BladeSetupScreen extends StatefulWidget {
  static const int patternCount = 5;

  const BladeSetupScreen({super.key});

  @override
  State<BladeSetupScreen> createState() => _BladeSetupScreenState();
}

class _BladeSetupScreenState extends State<BladeSetupScreen> {
  final FormData _formData =
      FormData(patternCount: BladeSetupScreen.patternCount);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const BladeSetupAppBar(),
        drawer: const MainDrawer(),
        floatingActionButton: ShowSetupButton(onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
          }
        }),
        body: SlitPatternList(
          formKey: _formKey,
          formData: _formData,
        ).wrapWithPadding(padding: const EdgeInsets.all(8)));
  }
}

class SlitPatternList extends StatelessWidget {
  final FormData _formData;
  final GlobalKey<FormState> _formKey;

  const SlitPatternList(
      {super.key,
      required GlobalKey<FormState> formKey,
      required FormData formData})
      : _formKey = formKey,
        _formData = formData;

  @override
  Widget build(BuildContext context) => [
        Form(
          key: _formKey,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
            },
            children: [
              // --- 1. HEADER ROW ---
              const TableRow(children: [
                Text('巾(mm)',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('本数',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold))
              ]),

              // --- 2. INPUT ROWS ---
              ..._formData.slitPatterns.map((item) => TableRow(children: [
                    WidthTextFormField(item: item),
                    SlitPatternCountDropDownMenu(
                      item: item,
                    )
                  ]))
            ],
          ),
        )
      ]
          .wrapWithColumn(mainAxisSize: MainAxisSize.min)
          .wrapWithInputDecorator(
            decoration: InputDecoration(
              labelText: 'スリットパターン',
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              contentPadding:
                  const EdgeInsets.all(16), // Padding inside the box
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
          .wrapWithContainer(
              constraints: const BoxConstraints(minWidth: 210),
              padding: const EdgeInsets.all(8));
}

class WidthTextFormField extends StatelessWidget {
  final FormSlitPatternItem _item;

  const WidthTextFormField({
    super.key,
    required FormSlitPatternItem item,
  }) : _item = item;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
        onChanged: (value) => _item.width = value,
        validator: (_) => _item.validateWidth());
  }
}

class BladeSetupAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BladeSetupAppBar({super.key});

  @override
  Widget build(BuildContext context) => AppBar(
        title: [const Icon(Icons.cut), const Text('セット替え')]
            .wrapWithRow(spacing: 8),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.print),
            tooltip: '印刷',
          )
        ],
        actionsPadding: const EdgeInsets.only(right: 24),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SlitPatternCountDropDownMenu extends StatelessWidget {
  final FormSlitPatternItem item;

  const SlitPatternCountDropDownMenu({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final entries = [const DropdownMenuEntry<int?>(label: '', value: null)] +
        List.generate(
            20,
            (i) => DropdownMenuEntry(
                value: i + 1,
                label: '${i + 1}本',
                labelWidget: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('${i + 1}本', textAlign: TextAlign.right),
                )));

    return DropdownMenuFormField<int?>(
      expandedInsets: EdgeInsets.zero,
      textAlign: TextAlign.right,
      requestFocusOnTap: false,
      dropdownMenuEntries: entries,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      onSelected: (value) => item.count = value,
      validator: (_) => item.validateCount(),
    );
  }
}

class ShowSetupButton extends StatelessWidget {
  final VoidCallback _onPressed;

  const ShowSetupButton({super.key, required VoidCallback onPressed})
      : _onPressed = onPressed;

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        onPressed: _onPressed,
        tooltip: '組合せ表示',
        child: const Icon(Icons.manage_search),
      );
}

class ClearPatternButton extends StatelessWidget {
  final VoidCallback _onClicked;

  const ClearPatternButton({super.key, required VoidCallback onClicked})
      : _onClicked = onClicked;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.delete_sweep),
        tooltip: 'クリア',
        onPressed: _onClicked,
      ).wrapWithAlign(alignment: Alignment.centerRight);
}

class FormData {
  late final List<FormSlitPatternItem> slitPatterns;

  FormData({int patternCount = 0}) {
    slitPatterns = List.generate(
        patternCount,
        (i) => FormSlitPatternItem(
            width: '',
            count: null,
            isRequired: () => _patternItemIsRequired(i)));
  }
  int get lastFilledLine =>
      slitPatterns.lastIndexWhere((item) => !item.isEmpty);

  bool _patternItemIsRequired(int index) =>
      index == 0 ? true : index <= lastFilledLine;
}

class FormSlitPatternItem {
  String width;
  int? count;
  final bool Function() isRequired;

  FormSlitPatternItem(
      {required this.width, this.count, required this.isRequired});

  bool get isEmpty => width.isEmpty && count == null;

  String? validateWidth() {
    if (width.isEmpty && isRequired()) {
      return '巾を入力してください';
    }
    if (width.isNotEmpty && int.tryParse(width) == null) {
      return '数値を入力してください';
    }
    return null;
  }

  String? validateCount() {
    if (count == null && isRequired()) {
      return '本数を選択してください';
    }
    return null;
  }
}

class SlitRequest {
  final List<SlitPatternItem> _slitPatterns;

  List<SlitPatternItem> get slitPatterns => UnmodifiableListView(_slitPatterns);

  SlitRequest({required List<SlitPatternItem> slitPatterns})
      : _slitPatterns = slitPatterns;
}

class SlitPatternItem {
  final int width;
  final int count;

  SlitPatternItem({required this.width, required this.count});
}
