import 'package:flutter/material.dart';
import 'package:line_please/constants.dart';
import 'package:line_please/models/script.dart';

class ScriptListPage extends StatelessWidget {
  final List<Script> scripts;

  ScriptListPage({Key key, @required this.scripts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Scripts'),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => Divider(),
        itemCount: scripts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(scripts[index].title),
            subtitle: Text('Scenes: ${scripts[index].scenes.length}'),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              Navigator.pushNamed(context, sceneListRoute, arguments: scripts[index]);
            },
          );
        },
      ),
    );
  }
}