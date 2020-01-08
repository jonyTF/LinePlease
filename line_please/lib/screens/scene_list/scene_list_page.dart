import 'package:flutter/material.dart';
import 'package:line_please/models/script.dart';
import 'package:line_please/models/scene.dart';
import 'package:line_please/constants.dart';

class SceneListPageState extends State<SceneListPage> {
  TextEditingController _nameTextFieldController;

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
        final name = await _getSceneName();
        if (name != null) {
          setState(() {
            widget.script.scenes.add(Scene(name: name));
          });
        }
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

  @override
  void initState() {
    super.initState();
    _nameTextFieldController = TextEditingController();
  }

  Future<String> _getSceneName() async {
    _nameTextFieldController.text = 'Scene ${widget.script.scenes.length + 1}';
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Scene'),
          content: TextField(
            controller: _nameTextFieldController,
          ),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('CANCEL'),
            ),
            new FlatButton(
              onPressed: () {
                Navigator.pop(context, _nameTextFieldController.text);
              },
              child: Text('OK'),
            ),
          ],
        );
      }
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