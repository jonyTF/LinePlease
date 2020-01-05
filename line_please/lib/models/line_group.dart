import 'package:flutter/material.dart';
import 'package:line_please/util/geom_utils.dart' as geom;

class LineGroup {
  // Contains a list of rects which represents one of the character's lines.

  static List<LineGroup> allLineGroups = [];

  static void clearLineGroups() {
    allLineGroups = [];
  }

  // rects            | The list of rects within this LineGroup.
  // boundingBox      | The bounding box of the list of rects.
  // isCharacterName  | Whether this lineGroup contains exclusively the name
  // ...              | of the character
  List<Rect> rects;
  Rect boundingBox;
  bool isCharacterName;

  LineGroup({@required this.rects, this.isCharacterName: false}) :
    boundingBox = geom.getBoundingBoxFromRects(rects) {
    allLineGroups.add(this);
  }

  void add(List<Rect> newRects) {
    rects.addAll(newRects);
    boundingBox = geom.getBoundingBoxFromRects(rects);
  }

  @override
  String toString() {
    return 'LineGroup{ index:${LineGroup.allLineGroups.indexOf(this)} rects[${rects.length}] isCharacterName:$isCharacterName }';
  }
}