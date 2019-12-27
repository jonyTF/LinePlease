import 'package:flutter/material.dart';

class ImageOverlayPainter extends CustomPainter {
  final int imWidth;
  final int imHeight;
  final Map<String, List<List<Rect>>> textData;
  final String character;

  ImageOverlayPainter({@required this.textData, @required this.imWidth, @required this.imHeight, @required this.character});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final ratioW = size.width/imWidth;
    final ratioH = size.height/imHeight;
    //print('RATIO_W: $ratioW, RATIO_H: $ratioH');

    for (String char in textData.keys) {
      for (List<Rect> lineRects in textData[char]) {
        for (Rect r in lineRects) {
          //print('OLD_RECT: $r');
          final left = r.left * ratioW;
          final right = r.right * ratioW;
          final top = r.top * ratioH;
          final bottom = r.bottom * ratioH;
          final middleX = (left+right)/2;
          final middleY = (top+bottom)/2;
          //Rect new_rect = Rect.fromLTRB(left, top, right, bottom);
          //print('NEW_RECT : $new_rect');

          paint.color = Colors.red;

          if (char == character) {
            canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
          } else {
            canvas.drawLine(Offset(left, top), Offset(right, top), paint);
            canvas.drawLine(Offset(left, bottom), Offset(right, bottom), paint);
            canvas.drawLine(Offset(left, top), Offset(left, bottom), paint);
            canvas.drawLine(Offset(right, top), Offset(right, bottom), paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(ImageOverlayPainter oldDelegate) {
    return oldDelegate.character != character;
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