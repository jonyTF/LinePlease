import 'package:flutter/material.dart';

Rect getBoundingBoxFromRects(List<Rect> rects) {
  var minTop = rects[0].top;
  var minLeft = rects[0].left;
  var maxRight = rects[0].right;
  var maxBot = rects[0].bottom;

  for (var i = 1; i < rects.length; i++) {
    final top = rects[i].top;
    final left = rects[i].left;
    final right = rects[i].right;
    final bot = rects[i].bottom;
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

  return Rect.fromLTRB(minLeft, minTop, maxRight, maxBot);
}