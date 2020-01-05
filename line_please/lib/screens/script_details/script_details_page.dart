import 'dart:io';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:line_please/constants.dart';
import 'package:line_please/models/char_mod_action.dart';
import 'package:line_please/models/script.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_please/screens/script_details/widgets/image_overlay_painter.dart';
import 'package:line_please/models/line_group.dart';

import 'package:line_please/util/geom_utils.dart' as geom;

class ScriptDetailsPageState extends State<ScriptDetailsPage> {
  final Script script;
  File imageFile;
  // TODO: Turn this List<List<Rect>> BS into its own class, perhaps a LineGroup class
  Map<String, List<LineGroup>> textData = HashMap<String, List<LineGroup>>();
  int imWidth;
  int imHeight;
  String curCharacter;

  ScriptDetailsPageState({@required this.script}) {
    //TODO: Make this not hardcoded
    LineGroup.clearLineGroups();
  }

  @override
  Widget build(BuildContext context) {
    if (imageFile == null)
      _getTextData();

    print('REPAINTED...character is $curCharacter');

    final Widget imageOverlay = CustomPaint(
      foregroundPainter: ImageOverlayPainter(textData: textData, imWidth: imWidth, imHeight: imHeight, character: curCharacter),
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
    // TODO: Change this to something more correct
    // Needed before modifying textData to make sure that it repaints the
    // image overlay correctly
    setState(() {});

    for (CharModAction action in actions) {
      switch (action.action) {
        case CharModAction.CHOOSE:
          _setCharacter(action.data[0]);
          break;

        case CharModAction.DELETE:
          _deleteCharacters(action.data);
          break;

        case CharModAction.MERGE:
          String mergeCharacter = action.data[0];
          List<String> charactersToMerge = action.data.sublist(1);
          _mergeCharacters(mergeCharacter, charactersToMerge);
          break;

        case CharModAction.RENAME:
          String oldName = action.data[0];
          String newName = action.data[1];
          _renameCharacter(oldName, newName);
          break;
      }
    }

    print(textData.keys);

    // TODO: Change this to something more correct
    setState(() {});
  }

  void _setCharacter(String character) {
    curCharacter = character;
  }

  void _deleteCharacters(List<String> characters) {
    // Add these characters' lines to the previously detected
    // characters lines, if there is such a previous character
    // Then delete the character.

    print('DELETE Characters!!!!');
    print(textData);
    for (String characterToRemove in characters) {
      for (LineGroup lineGroup in textData[characterToRemove]) {
        _mergeLineGroupUp(lineGroup);
      }
      textData.remove(characterToRemove);
    }
    print(textData);
  }

  void _mergeLineGroupUp(LineGroup lineGroup) {
    // Keep on merging the lineGroups up the page until the lineGroup does
    // not represent a character.
    int index = LineGroup.allLineGroups.indexOf(lineGroup) - 1;
    LineGroup.allLineGroups.remove(lineGroup);

    if (index >= 0) {
      final newLineGroup = LineGroup.allLineGroups[index];
      newLineGroup.add(lineGroup.rects);
      if (newLineGroup.isCharacterName) {
        _mergeLineGroupUp(newLineGroup);
      }
    }
  }

  void _mergeCharacters(String mergeCharacter, List<String> charactersToMerge) {
    List<LineGroup> mergeLines = [];
    for (String character in charactersToMerge) {
      mergeLines.addAll(textData[character]);
      textData.remove(character);
    }
    textData[mergeCharacter].addAll(mergeLines);
  }

  void _renameCharacter(String oldName, String newName) {
    textData[newName] = textData[oldName];
    textData.remove(oldName);
  }

  void _processScript(VisionText visionText) {
    // ---- FOR TESTING ------ //
    textData['test'] = [];
    /*for (TextBlock block in visionText.blocks) {
      textData['test'].add([block.boundingBox]);
    }*/
    // ---------------------- //

    // Flatten the visionText blocks list to put all the lines in a single list
    var allLines = visionText.blocks.expand((block) => block.lines).toList();
    // Sort the lines by their y coordinates
    allLines.sort((line1, line2) => (line1.boundingBox.top - line2.boundingBox.top) > 0 ? 1 : -1);

    // Create textData map
    String curNameString = '';
    List<TextElement> curName = [];
    List<List<TextElement>> curWords = [];
    for (final line in allLines) {
      final firstWord = line.elements[0].text;
      if (_isName(firstWord)) {
        // If the current line has a name in it
        if (curNameString.length > 0) {
          if (curWords.length > 0) {
            // Add the current lines to the previous character's
            _addToCharacterLines(curNameString, curName, curWords);
          }
          curNameString = '';
          curName = [];
          curWords = [];
        }

        // Go through the entire line and add to the name if the name is
        // multiple words long
        curNameString = firstWord;
        var i;
        for (i = 1; i < line.elements.length; i++) {
          if (_isName(line.elements[i].text))
            curNameString += ' ' + line.elements[i].text;
          else
            break;
        }

        curName = line.elements.sublist(0, i);

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

  bool _isName(String text) => text.length >= 2 && text == text.toUpperCase();

  void _addToCharacterLines(String curNameString, List<TextElement> curName, List<List<TextElement>> curWords) {
    // TODO: How do I account for the case in which it detects two blocks on the same line?
    // Maybe I don't need to? Or else it might cover up more than it should...
    // (if the image is slightly slanted)
    // TODO: How do I account for when there are songs? (all words are in caps)

    // Get a single rectangle that bounds all the words in a given line
    final List<Rect> lineRects = [];
    for (List<TextElement> lineElement in curWords) {
      final wordRects = List.generate(lineElement.length, (int index) => lineElement[index].boundingBox);
      final rect = geom.getBoundingBoxFromRects(wordRects);
      lineRects.add(rect);
    }

    // Instantiating nameLineGroup adds it to the allLineGroups list
    // TODO: figure out whether to add nameLineGroup to textData or not.
    // (maybe use it to make sure that the name is not blocked by any stray
    // lines)
    final nameRects = List.generate(curName.length, (int index) => curName[index].boundingBox);
    final nameLineGroup = LineGroup(rects: nameRects, isCharacterName: true);

    final lineGroup = LineGroup(rects: lineRects);
    // Add lineRects to the textData map;
    if (textData.containsKey(curNameString)) {
      textData[curNameString].add(nameLineGroup);
      textData[curNameString].add(lineGroup);
    } else {
      textData[curNameString] = [nameLineGroup];
      textData[curNameString] = [lineGroup];
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