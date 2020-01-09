import 'package:flutter/material.dart';
import 'package:line_please/models/script.dart';
import 'package:line_please/models/scene.dart';
import 'package:line_please/constants.dart';

class SceneListPageState extends State<SceneListPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: Add select multiple functionality
    // TODO: Add rename/delete functionality
    // TODO: Implement persisting of data (scenes added) when going back

    final sceneList = ListView.separated(
        separatorBuilder: (context, index) => Divider(),
        itemCount: widget.script.scenes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(widget.script.scenes[index].name),
            subtitle: Text('Pages: ${widget.script.scenes[index].images.length}'),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              Navigator.pushNamed(context, sceneDetailsRoute, arguments: widget.script.scenes[index]);
            },
          );
        }
    );

    final addSceneBtn = FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () async {
        final result = Navigator.pushNamed(context, newSceneRoute, arguments: widget.script.scenes.length);
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.script.title),
      ),
      body: sceneList,
      floatingActionButton: addSceneBtn,
    );
  }
}

class SceneListPage extends StatefulWidget {
  final Script script;

  SceneListPage({Key key, @required this.script}) : super(key: key);

  @override
  SceneListPageState createState() {
    return SceneListPageState();
  }
}