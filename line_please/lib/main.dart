import 'dart:ui';

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
  String character;

  ScriptDetailsPageState({@required this.script});

  @override
  Widget build(BuildContext context) {
    if (imageFile == null)
      _getTextData();

    print('REPAINTED...character is $character');

    Widget imageOverlay = CustomPaint(
      foregroundPainter: ImageOverlayPainter(textData: textData, imWidth: imWidth, imHeight: imHeight, character: character),
      child: imageFile != null ? Image.file(imageFile) : Image.asset('assets/img/test.jpg'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(script.title),
      ),
      body: ListView(
        children: [
          Text('Page count: ${script.pageCount}'),
          RaisedButton(
            onPressed: _chooseCharacter,
            child: const Text('Change character'),
          ),
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

    _processScript(visionText);

    setState(() {
      imageFile = f;
      imWidth = decodedImage.width;
      imHeight = decodedImage.height;
    });

    await _chooseCharacter();
  }

  Future<void> _chooseCharacter() async {
    final char = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: const Text('Choose character'),
              children: textData.keys.map((character) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, character),
                  child: Text(character),
                );
              }).toList(),
          );
        }
    );
    setState(() {
      character = char;
    });
  }

  void _processScript(VisionText visionText) {

    textData['test'] = [];
    var curName = '';
    var curWords = <List<TextElement>>[];

    // ---- FOR TESTING ------ //
    /*for (TextBlock block in visionText.blocks) {
      textData['test'].add([block.boundingBox]);
    }*/
    // ---------------------- //

    // Flatten the visionText blocks list to put all the lines in a single list
    var allLines = visionText.blocks.expand((block) => block.lines).toList();
    // Sort the lines by their y coordinates
    allLines.sort((line1, line2) => (line1.boundingBox.top - line2.boundingBox.top) > 0 ? 1 : -1);
    for (TextLine line in allLines) {
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

  // TODO: Fix the bug where "20" is considered a character
  // But is there any way to fix this? What if 20 is the name of an actual character?
  // Solution: in the character selection dialogue, user can "trash" certain
  // characters that are not actually characters, but mis-detections.
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
  final Map<String, List<List<Rect>>> textData;
  final String character;

  ImageOverlayPainter({@required this.textData, @required this.imWidth, @required this.imHeight, @required this.character});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final ratioW = size.width/imWidth;
    final ratioH = size.height/imHeight;
    //print('RATIO_W: $ratioW, RATIO_H: $ratioH');

    for (String char in textData.keys) {
      for (List<Rect> lineRects in textData[char]) {
        for (Rect r in lineRects) {
          //print('OLD_RECT: $r');
          final left = r.left * ratioW;
          final right = r.right * ratioW;
          final top = r.top * ratioH;
          final bottom = r.bottom * ratioH;
          final middleX = (left+right)/2;
          final middleY = (top+bottom)/2;
          //Rect new_rect = Rect.fromLTRB(left, top, right, bottom);
          //print('NEW_RECT : $new_rect');

          paint.color = Colors.red;

          if (char == character) {
            canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
          } else {
            canvas.drawLine(Offset(left, top), Offset(right, top), paint);
            canvas.drawLine(Offset(left, bottom), Offset(right, bottom), paint);
            canvas.drawLine(Offset(left, top), Offset(left, bottom), paint);
            canvas.drawLine(Offset(right, top), Offset(right, bottom), paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(ImageOverlayPainter oldDelegate) {
    return oldDelegate.character != character;
  }

  void _drawText(Canvas canvas, String text, double x, double y, Size size, Color color) {
    final textStyle = TextStyle(
      color: color,
      fontSize: 10,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    final offset = Offset(x, y);
    textPainter.paint(canvas, offset);
  }
}