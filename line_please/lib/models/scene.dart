import 'dart:io';

import 'package:flutter/material.dart';

class Scene {
  final String name;
  List<File> images;

  Scene({@required this.name, this.images: const []});
}