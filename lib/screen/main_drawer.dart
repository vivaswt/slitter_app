import 'package:flutter/material.dart';
import 'package:slitter_app/extension/widget_wrap.dart';
import 'package:slitter_app/screen/log.dart';
import 'package:slitter_app/screen/mini_label_print.dart';
import 'package:slitter_app/screen/setting.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: <Widget>[
      const DrawerHeader(
        decoration: BoxDecoration(color: Colors.blue),
        child: Text('メニュー'),
      ),
      ListTile(
        title: const Text('ミニラベル印刷'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const MiniLabelPrint()));
        },
        leading: const Icon(Icons.label),
      ),
      ListTile(
        title: const Text('設定'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const SettingScreen()));
        },
        leading: const Icon(Icons.settings),
      ),
      ListTile(
        title: const Text('ログ'),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LogScreen()),
          );
        },
        leading: const Icon(Icons.history),
      )
    ].wrapWithListView(padding: EdgeInsets.zero));
  }
}
