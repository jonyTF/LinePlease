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

class ScriptDetailsPageState extends State<ScriptDetailsPage> {
  final Script script;
  File imageFile;
  final List<Rect> textData = <Rect>[];
  int im_width;
  int im_height;

  ScriptDetailsPageState({@required this.script});

  @override
  Widget build(BuildContext context) {
    if (imageFile == null)
      _getTextData();

    Widget imageOverlay = CustomPaint(
      foregroundPainter: ImageOverlayPainter(textData: textData, im_width: im_width, im_height: im_height),
      child: imageFile != null ? Image.file(imageFile) : Image.asset('assets/img/test.jpg'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(script.title),
      ),
      body: ListView(
        children: [
          Text('Page count: ${script.pageCount}'),
          imageOverlay,
        ],
      ),
    );
  }

  Future<void> _getTextData() async {
    final File f = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    final decodedImage = await decodeImageFromList(f.readAsBytesSync());
    print('WIDTH: ${decodedImage.width}, HEIGHT: ${decodedImage.height}');

    //final File imageFile = new File('assets/img/test_edited.jpg');
    //final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFilePath('assets/img/test_edited.jpg');
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(f);

    final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    print(visionText.text);

    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        final Rect boundingBox = line.boundingBox;
        textData.add(boundingBox);
      }
    }

    textRecognizer.close();

    setState(() {
      imageFile = f;
      im_width = decodedImage.width;
      im_height = decodedImage.height;
    });
  }
}

class ScriptDetailsPage extends StatefulWidget {
  final Script script;

  ScriptDetailsPage({@required this.script});

  @override
  ScriptDetailsPageState createState() {
    return ScriptDetailsPageState(script: script);
  }
}

class ImageOverlayPainter extends CustomPainter {
  final int im_width;
  final int im_height;
  final List<Rect> textData;

  ImageOverlayPainter({@required this.textData, @required this.im_width, @required this.im_height});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.red;

    final ratio_w = size.width/im_width;
    final ratio_h = size.height/im_height;
    //print('RATIO_W: $ratio_w, RATIO_H: $ratio_h');

    for (Rect r in textData) {
      //print('OLD_RECT: $r');
      final left = r.left * ratio_w;
      final right = r.right * ratio_w;
      final top = r.top * ratio_h;
      final bottom = r.bottom * ratio_h;
      //Rect new_rect = Rect.fromLTRB(left, top, right, bottom);
      //print('NEW_RECT : $new_rect');
      
      canvas.drawLine(Offset(left, top), Offset(right, top), paint);
      canvas.drawLine(Offset(left, bottom), Offset(right, bottom), paint);
      canvas.drawLine(Offset(left, top), Offset(left, bottom), paint);
      canvas.drawLine(Offset(right, top), Offset(right, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}