import 'package:flutter/material.dart';
import 'package:slitter_app/screen/main_drawer.dart';
import 'package:slitter_app/service/log.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const MainDrawer(),
        body: Builder(
          builder: (context) => TalkerScreen(
            talker: talker,
            appBarLeading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      );
}
