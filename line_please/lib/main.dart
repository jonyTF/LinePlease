import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScriptDetailsPage(script: scripts[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ScriptDetailsPage extends StatelessWidget {
  final Script script;

  ScriptDetailsPage({Key key, @required this.script}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _getTextData();

    return Scaffold(
      appBar: AppBar(
        title: Text(script.title),
      ),
      body: ListView(
        children: [
          Text('Page count: ${script.pageCount}'),
          Image.asset('assets/img/test_edited.jpg'),
        ],
      ),
    );
  }

  Future<void> _getTextData() async {
    final File imageFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //final File imageFile = new File('assets/img/test_edited.jpg');
    //final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFilePath('assets/img/test_edited.jpg');
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(imageFile);

    final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    print('READY to print!');
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          print(element.text);
        }
      }
    }

    textRecognizer.close();
  }
}