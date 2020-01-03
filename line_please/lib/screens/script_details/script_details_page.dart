import 'dart:io';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:line_please/constants.dart';
import 'package:line_please/models/char_mod_action.dart';
import 'package:line_please/models/script.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_please/screens/script_details/widgets/image_overlay_painter.dart';

class ScriptDetailsPageState extends State<ScriptDetailsPage> {
  final Script script;
  File imageFile;
  // TODO: Turn this List<List<Rect>> BS into its own class, perhaps a LineGroup class
  Map<String, List<List<Rect>>> textData = HashMap<String, List<List<Rect>>>();
  int imWidth;
  int imHeight;
  String character;

  ScriptDetailsPageState({@required this.script});

  @override
  Widget build(BuildContext context) {
    if (imageFile == null)
      _getTextData();

    print('REPAINTED...character is $character');

    final Widget imageOverlay = CustomPaint(
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

    _chooseCharacter();
  }

  void _chooseCharacter() async {
    final result = await Navigator.pushNamed(context, characterSelectRoute, arguments: textData.keys.toList());
    print('RESULT: $result');
    _modifyTextData(result);
  }

  void _modifyTextData(List<CharModAction> actions) {
    for (CharModAction action in actions) {
      switch (action.action) {
        case CharModAction.CHOOSE:
          character = action.data[0];
          break;
        case CharModAction.DELETE:
          // Somehow add these characters' lines to the previously detected
          // characters lines, if there is such a previous character

          // TEMPORARY:
          for (String character in action.data) {
            textData.remove(character);
          }
          break;
        case CharModAction.MERGE:
          String mergeChar = action.data[0];

          List<List<Rect>> mergeLines = [];
          for (int i = 1; i < action.data.length; i++) {
            mergeLines.addAll(textData[action.data[i]]);
            textData.remove(action.data[i]);
          }
          textData[mergeChar].addAll(mergeLines);
          break;
        case CharModAction.RENAME:
          String oldName = action.data[0];
          String newName = action.data[1];

          textData[newName] = textData[oldName];
          textData.remove(oldName);
          break;
      }
    }

    print(textData.keys);

    setState(() {
      textData = textData;
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

  ScriptDetailsPage({Key key, @required this.script}) : super(key: key);

  @override
  ScriptDetailsPageState createState() {
    return ScriptDetailsPageState(script: script);
  }
}