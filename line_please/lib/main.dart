import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Line Please',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScriptListPage(
        scripts: List.generate(
          20,
          (i) => Script(
            'Script $i',
            i,
          )
        ),
      ),
    );
  }
}

class Script {
  final String title;
  final int pageCount;

  Script(this.title, this.pageCount);
}

class ScriptListPage extends StatelessWidget {
  final List<Script> scripts;

  ScriptListPage({Key key, @required this.scripts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('My Scripts'),
      ),
      body: ListView.builder(
        itemCount: scripts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(scripts[index].title),
            onTap: () {
              
            },
          );
        },
      ),
    );
  }
}