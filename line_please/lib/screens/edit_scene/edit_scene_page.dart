import 'package:flutter/material.dart';
import 'package:line_please/models/scene.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class EditScenePageState extends State<EditScenePage> {
  TextEditingController _nameTextFieldController;
  Scene _scene;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _nameTextFieldController = TextEditingController();
    
    if (widget.isNewScene) {
      _nameTextFieldController.text = 'Scene ${widget.numScenes + 1}';
      _scene = Scene(name: _nameTextFieldController.text);
    } else {
      _nameTextFieldController.text = _scene.name;
      _scene = widget.scene;
    }
    print('SCENE NAME: ${_scene.name}');
  }

  @override
  void dispose() {
    _nameTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget nameTextField = Container(
      padding: const EdgeInsets.only(
        top: 32,
        left: 32,
        right: 32,
        bottom: 16,
      ),
      child: TextField(
        controller: _nameTextFieldController,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Scene Name',
        ),
        onChanged: (text) {
          _scene.name = text;
          print('SCENE NAME: ${_scene.name}');
        },
      )
    );

    Widget imageDisplay;
    if (_scene.images.length > 0) {
      // Display images
    } else {
      // Display message prompting user to add images
      imageDisplay = Expanded(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment(0, -0.3),
          child: Container(
            padding: EdgeInsets.only(
              left: 32,
              right: 32,
            ),
            child: Text('Add some script pages to get started!'),
          ),
        )
      );
    }

    Widget addImageBtn = SpeedDial(
      child: _isSpeedDialOpen ? Icon(Icons.close) : Icon(Icons.add_to_photos),
      onOpen: () => setState(() {
        _isSpeedDialOpen = true;
      }),
      onClose: () => setState(() {
        _isSpeedDialOpen = false;
      }),
      overlayColor: Colors.grey,
      backgroundColor: _isSpeedDialOpen ? Colors.white : Theme.of(context).primaryColor,
      foregroundColor: _isSpeedDialOpen ? Colors.grey : Colors.white,
      children: [
        SpeedDialChild(
          child: Icon(Icons.add_a_photo),
          onTap: () {
            // TODO: probably want to implement my own custom camera
            // and not use the one that comes with the multi image picker,
            // since that one actually adds more photos to your gallery.
            // Instead, do something where you can take multiple photos, like
            // the google drive scanning thing, and save photos to a line_please
            // folder
            print('TAKE PHOTO');
          }
        ),
        SpeedDialChild(
            child: Icon(Icons.add_photo_alternate),
            onTap: () {
              print('OPEN GALLERY');
              _openGallery();
            }
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: widget.isNewScene ? Text('New Scene') : Text('Edit Scene'),
      ),
      body: Column(
        children: <Widget>[
          nameTextField,
          imageDisplay,
        ],
      ),
      floatingActionButton: addImageBtn,
    );
  }

  void _openGallery() async {
    try {
      final results = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        materialOptions: MaterialOptions(
          actionBarTitle: 'Choose photos',
          allViewTitle: 'Gallery',
          actionBarColor: '#${Theme.of(context).primaryColor.value.toRadixString(16)}',
        ),
      );
      print(results);
    } on Exception catch (e) {
      print('ERROR: $e');
    }
  }
}

class EditScenePage extends StatefulWidget {
  final bool isNewScene;
  final int numScenes;
  final Scene scene;

  EditScenePage({Key key, @required this.isNewScene, this.numScenes: -1, this.scene});

  @override
  EditScenePageState createState() {
    return EditScenePageState();
  }
}