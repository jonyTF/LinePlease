//https://flutter.dev/docs/development/ui/interactive#the-parent-widget-manages-the-widgets-state
import 'package:flutter/material.dart';

class CharacterTile extends StatelessWidget {
  final bool selected;
  final String character;
  final ValueChanged<String> onTap;

  CharacterTile({Key key, @required this.selected: false, @required this.character, @required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? Colors.grey[400] : Colors.white,
      child: ListTile(
        title: Text(character),
        onTap: _handleTap,
        selected: selected,
      ),
    );
  }

  void _handleTap() {
    onTap(character);
  }
}