import 'package:flutter/material.dart';
import 'package:line_please/models/line.dart';

class LineGroup {
  // Contains a list of rects which represents one of the character's lines.

  static List<LineGroup> allLineGroups = [];

  static void clearLineGroups() {
    allLineGroups = [];
  }

  // rects            | The list of rects within this LineGroup.
  // isCharacterName  | Whether this lineGroup contains exclusively the name
  // ...              | of the character
  List<Line> lines;
  bool isCharacterName;

  LineGroup({@required this.lines, this.isCharacterName: false}) {
    allLineGroups.add(this);
  }

  void add(List<Line> newLines) {
    lines.addAll(newLines);
  }

  @override
  String toString() {
    return 'LineGroup{ index:${LineGroup.allLineGroups.indexOf(this)} rects[${lines.length}] isCharacterName:$isCharacterName }';
  }
}