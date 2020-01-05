import 'package:flutter/material.dart';

class CharModAction {
  // Class that contains the actions that need to be performed on the
  // characters that were detected with OCR. (Character modifications)

  static const int MERGE = 0;
  static const int DELETE = 1;
  static const int RENAME = 2;
  static const int CHOOSE = 3;

  final int action;
  final List<String> data;

  CharModAction({@required this.action, @required this.data});

  @override
  String toString() {
    String s = '';
    switch (action) {
      case MERGE:
        s += 'MERGE ';
        break;
      case DELETE:
        s += 'DELETE ';
        break;
      case RENAME:
        s += 'RENAME ';
        break;
      case CHOOSE:
        s += 'CHOOSE ';
        break;
    }
    s += data.toString();
    return s;
  }
}