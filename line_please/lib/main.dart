import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:collection';

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
  final Map<String, List<List<Rect>>> textData = HashMap<String, List<List<Rect>>>();
  int imWidth;
  int imHeight;

  ScriptDetailsPageState({@required this.script});

  @override
  Widget build(BuildContext context) {
    if (imageFile == null)
      _getTextData();

    Widget imageOverlay = CustomPaint(
      foregroundPainter: ImageOverlayPainter(textData: textData, imWidth: imWidth, imHeight: imHeight),
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
    textRecognizer.close();

    print(visionText.text);

    _processScriptPage(visionText);

    setState(() {
      imageFile = f;
      imWidth = decodedImage.width;
      imHeight = decodedImage.height;
    });
  }

  void _processScriptPage(VisionText visionText) {

    var curName = '';
    var curWords = <List<TextElement>>[];
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        final firstWord = line.elements[0].text;
        if (_isName(firstWord)) {
          // If the current line has a name in it
          if (curName.length > 0) {
            if (curWords.length > 0) {
              // Add the current lines to the previous character's
              _addToCharacterLines(curName, curWords);
            }
            curName = '';
            curWords = <List<TextElement>>[];
          }

          // Go through the entire line and add to the name if the name is
          // multiple words long
          curName = firstWord;
          var i;
          for (i = 1; i < line.elements.length; i++) {
            if (_isName(line.elements[i].text))
              curName += ' ' + line.elements[i].text;
            else
              break;
          }

          // Add the rest of the words in the line
          final words = line.elements.sublist(i);
          if (words.length > 0) {
            curWords.add(words);
          }
        } else {
          // Current line does not contain a name, so add all
          // the words in the current line
          final words = line.elements;
          if (words.length > 0) {
            curWords.add(words);
          }
        }
      }
    }
  }

  bool _isName(String text) => text.length >= 2 && text == text.toUpperCase();

  void _addToCharacterLines(String curName, List<List<TextElement>> curWords) {
    // TODO: How do I account for the case in which it detects two blocks on the same line?
      // Maybe I don't need to? Or else it might cover up more than it should...
      // (if the image is slightly slanted)
    final List<Rect> lineRects = <Rect>[];

    // Get a single rectangle that bounds all the words in a given line
    for (List<TextElement> lineElement in curWords) {
      // This is necessary to account for the case where the name and
      // line are on the same line
      var minTop = lineElement[0].boundingBox.top;
      var minLeft = lineElement[0].boundingBox.left;
      var maxRight = lineElement[0].boundingBox.right;
      var maxBot = lineElement[0].boundingBox.bottom;

      for (var i = 1; i < lineElement.length; i++) {
        final top = lineElement[i].boundingBox.top;
        final left = lineElement[i].boundingBox.left;
        final right = lineElement[i].boundingBox.right;
        final bot = lineElement[i].boundingBox.bottom;
        if (top < minTop) {
          minTop = top;
        }
        if (left < minLeft) {
          minLeft = left;
        }
        if (right > maxRight) {
          maxRight = right;
        }
        if (bot > maxBot) {
          maxBot = bot;
        }
      }

      final rect = Rect.fromLTRB(minLeft, minTop, maxRight, maxBot);
      lineRects.add(rect);
    }

    // Add lineRects to the textData map;
    if (textData.containsKey(curName)) {
      textData[curName].add(lineRects);
    } else {
      textData[curName] = [lineRects];
    }
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
  final int imWidth;
  final int imHeight;
  final List<Rect> textData;

  ImageOverlayPainter({@required this.textData, @required this.imWidth, @required this.imHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.red;

    final ratioW = size.width/imWidth;
    final ratioH = size.height/imHeight;
    //print('RATIO_W: $ratioW, RATIO_H: $ratioH');

    for (Rect r in textData) {
      //print('OLD_RECT: $r');
      final left = r.left * ratioW;
      final right = r.right * ratioW;
      final top = r.top * ratioH;
      final bottom = r.bottom * ratioH;
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