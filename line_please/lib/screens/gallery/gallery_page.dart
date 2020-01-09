import 'package:flutter/material.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class GalleryPageState extends State<GalleryPage> {
  List<Asset> _images;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Select images'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(),
        ],
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  @override
  GalleryPageState createState() {
    return GalleryPageState();
  }
}