import 'package:flutter/material.dart';
import 'package:slitter_app/extension/widget_wrap.dart';
import 'package:slitter_app/model/setting_service.dart';
import 'package:slitter_app/screen/main_drawer.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar:
          AppBar(title: const [Icon(Icons.settings), Text('設定')].wrapWithRow()),
      drawer: const MainDrawer(),
      body: const NotionApiKeyField()
          .wrapWithPadding(padding: const EdgeInsets.all(16)));
}

class NotionApiKeyField extends StatefulWidget {
  const NotionApiKeyField({super.key});

  @override
  State<NotionApiKeyField> createState() => _NotionApiKeyFieldState();
}

class _NotionApiKeyFieldState extends State<NotionApiKeyField> {
  late final Future<String> _notionApiKey;
  final _notionApiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notionApiKey = SettingsService().getNotionApiKey();
    _notionApiKey.then((key) {
      if (mounted) {
        _notionApiKeyController.text = key;
      }
    });
    _notionApiKeyController.addListener(() {
      SettingsService().setNotionApiKey(_notionApiKeyController.text);
    });
  }

  @override
  void dispose() {
    _notionApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _notionApiKey,
      builder: (context, snapshot) => TextFormField(
          controller: _notionApiKeyController,
          decoration: const InputDecoration(
            labelText: 'Notion API Key',
          ),
          enabled: snapshot.connectionState == ConnectionState.done));
}
