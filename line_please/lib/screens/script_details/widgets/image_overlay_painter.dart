import 'package:flutter/material.dart';
import 'package:line_please/models/line_group.dart';
import 'package:collection/collection.dart';
import 'package:line_please/models/line.dart';
import 'dart:ui';

class ImageOverlayPainter extends CustomPainter {
  static const int SELECT_MODE = 0; // Mode for enabling/disabling certain lines
  static const int ACTIVE_MODE = 1; // Mode for running through lines

  final int imWidth;
  final int imHeight;
  final Map<String, List<LineGroup>> textData;
  final String character;
  final int mode;

  ImageOverlayPainter({
    @required this.textData,
    @required this.imWidth,
    @required this.imHeight,
    @required this.character,
    @required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final ratioW = size.width/imWidth;
    final ratioH = size.height/imHeight;
    //print('RATIO_W: $ratioW, RATIO_H: $ratioH');

    for (String char in textData.keys) {
      for (LineGroup lineGroup in textData[char]) {
        for (Line line in lineGroup.lines) {
          Rect r = line.rect;
          //print('OLD_RECT: $r');
          final left = r.left * ratioW;
          final right = r.right * ratioW;
          final top = r.top * ratioH;
          final bottom = r.bottom * ratioH;
          //final middleX = (left+right)/2;
          //final middleY = (top+bottom)/2;
          Rect newRect = Rect.fromLTRB(left, top, right, bottom);
          //print('NEW_RECT : $new_rect');

          if (char == character) {
            if (lineGroup.isCharacterName) {
              canvas.clipRect(newRect,
                  clipOp: ClipOp.difference);
            } else {
              if (mode == SELECT_MODE) {
                paint.color = Colors.black;
                paint.style = PaintingStyle.stroke;
                paint.strokeWidth = 3;
                canvas.drawRect(newRect, paint);
                if (line.enabled) {
                  paint.color = Color.fromRGBO(50, 205, 50, 0.5);
                  paint.style = PaintingStyle.fill;
                  canvas.drawRect(newRect, paint);
                }
              }
            }
          } else {
            paint.color = Colors.black;
            paint.style = PaintingStyle.stroke;
            canvas.drawRect(newRect, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(ImageOverlayPainter oldDelegate) {
    // TODO: Make sure that this catches all cases of changes that could occur
    // TODO(BUG): Fix bug where it doesn't update correctly when textData is changed.
        // THIS bug was somehow fixed? I think it's because the photo view
        // keeps on repainting continuously?
    bool characterChanged = oldDelegate.character != character;
    //print('old textdata: ${oldDelegate.textData}');
    //print('new textdata: $textData');
    bool textDataKeysChanged = !ListEquality().equals(oldDelegate.textData.keys.toList(), textData.keys.toList());
    bool textDataChanged = !MapEquality().equals(oldDelegate.textData, textData);
    //print('characterChanged: $characterChanged, textDataKeysChanged: $textDataKeysChanged, textDataChanged: $textDataChanged');
    return characterChanged || textDataKeysChanged || textDataChanged;
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