import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:line_please/models/char_mod_action.dart';

class CharacterSelectPageState extends State {
  final List<String> characters;
  Map<String, bool> _selected = HashMap<String, bool>();
  List<CharModAction> _actionsToPerform = [];
  final _renameTextFieldController = TextEditingController();

  CharacterSelectPageState({@required this.characters}) {
    for (String character in characters) {
      _selected[character] = false;
    }
  }

  void dispose() {
    _renameTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget appBar = _buildAppBar();

    return Scaffold(
      appBar: appBar,
      body: ListView.builder(
        itemCount: characters.length,
        itemBuilder: (context, index) {
          String character = characters[index];
          return CharacterTile(
              selected: _selected[character],
              character: character,
              onLongPress: null,
              onTap: _select,
          );
        },
      ),
    );
  }

  List<String> _getCurSelected() {
    List<String> curSelected = <String>[];
    // TODO: Make this more efficient???
    for (String character in _selected.keys) {
      if (_selected[character])
        curSelected.add(character);
    }
    return curSelected;
  }

  void _select(String character) {
    setState(() {
      _selected[character] = !_selected[character];
    });
  }

  void _clearSelection() {
    for (String character in characters) {
      _selected[character] = false;
    }

    setState(() {
      _selected = _selected;
    });
  }

  Widget _buildAppBar() {
    List<String> curSelected = _getCurSelected();
    List<Widget> actions = _getActions(curSelected);

    if (curSelected.length > 0) {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: _clearSelection,
        ),
        actions: actions,
      );
    }

    return AppBar(
      title: Text('Character Selection'),
      actions: actions,
    );
  }

  List<Widget> _getActions(List<String> curSelected) {
    List<Widget> actions = <Widget>[];
    if (curSelected.length == 0) {
      // Add help button?
      actions.add(
        IconButton(
          icon: Icon(Icons.help, color: Colors.white),
          onPressed: () {
            print('HELP');
            _help();
          },
        )
      );
    } else if (curSelected.length == 1) {
      // Add button to select current character
      actions.addAll([
        FlatButton(
          onPressed: () {
            print('RENAME ${curSelected[0]}');
            _rename();
          },
          textColor: Colors.white,
          child: Text('RENAME'),
        ),
        FlatButton(
          onPressed: () {
            print('CHOSE ${curSelected[0]}');
            _choose();
          },
          textColor: Colors.white,
          child: Text('CHOOSE'),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.white),
          onPressed: () {
            print('DELETE ${curSelected}');
            _delete();
          },
        )
      ]);
    } else if (curSelected.length > 1) {
      // Add button to merge characters or delete characters
      actions.addAll([
        FlatButton(
          textColor: Colors.white,
          child: Text('MERGE'),
          onPressed: () {
            print('MERGE ${curSelected}');
            _merge();
          },
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.white),
          onPressed: () {
            print('DELETE ${curSelected}');
            _delete();
          },
        )
      ]);
    }

    return actions;
  }

  void _help() {
    // TODO: Show a tutorial on how to use this page
  }

  void _choose() {
    String character = _getCurSelected()[0];
    _actionsToPerform.add(
      CharModAction(action: CharModAction.CHOOSE, data: [character])
    );

    // Navigate back to script details page, passing _actionsToPerform in the arguments
    print(_actionsToPerform);
  }

  void _rename() async {
    String character = _getCurSelected()[0];

    final newName = await _getNewName(character);

    if (newName != null) {
      bool confirmed = await _getConfirmation(
        'Are you sure you would like to rename "$character" to "$newName"?'
      );
      if (!confirmed) {
        return;
      }

      _actionsToPerform.add(
          CharModAction(action: CharModAction.RENAME, data: [character, newName])
      );
      characters[characters.indexOf(character)] = newName;
      _selected[newName] = _selected[character];
      _selected.remove(character);

      _clearSelection();
    }
  }

  void _merge() async {
    List<String> curCharacters = _getCurSelected();

    final mergeName = await _getMergeName(curCharacters);

    if (mergeName != null) {
      bool confirmed = await _getConfirmation(
        'Are you sure you would like to merge the characters $curCharacters under "$mergeName"?'
      );
      if (!confirmed) {
        return;
      }

      curCharacters.remove(mergeName);
      curCharacters.insert(0, mergeName);
      _actionsToPerform.add(
          CharModAction(action: CharModAction.MERGE, data: curCharacters)
      );
      for (int i = 1; i < curCharacters.length; i++) {
        characters.remove(curCharacters[i]);
        _selected.remove(curCharacters[i]);
      }

      _clearSelection();
      _select(mergeName);
    }
  }

  void _delete() async {
    List<String> curCharacters = _getCurSelected();

    bool confirmed = await _getConfirmation(
      'Are you sure you would like to delete the characters $curCharacters?'
    );
    if (!confirmed) {
      return;
    }

    _actionsToPerform.add(
        CharModAction(action: CharModAction.DELETE, data: curCharacters)
    );
    for (String character in curCharacters) {
      characters.remove(character);
      _selected.remove(character);
    }

    setState(() {
      _selected = _selected;
    });
  }

  Future<String> _getMergeName(List<String> names) async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          // TODO: reword this to make it make more sense
          title: Text('Choose character to merge under'),
          children: names.map((name) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, name),
              child: Text(name),
            );
          }).toList(),
        );
      }
    );
  }

  Future<String> _getNewName(String currentName) async {
    _renameTextFieldController.text = currentName;
    return await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Rename character'),
            content: TextField(
              controller: _renameTextFieldController,
              textCapitalization: TextCapitalization.characters,
            ),
            actions: <Widget>[
              new FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CANCEL'),
              ),
              new FlatButton(
                onPressed: () {
                  Navigator.pop(context, _renameTextFieldController.text);
                },
                child: Text('RENAME'),
              )
            ],
          );
        }
    );
  }

  Future<bool> _getConfirmation(String message) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('NO'),
            ),
            new FlatButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('YES'),
            )
          ],
        );
      },
    );
  }
}

class CharacterSelectPage extends StatefulWidget {
  final List<String> characters;

  CharacterSelectPage({Key key, @required this.characters}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CharacterSelectPageState(characters: characters);
  }
}

//https://flutter.dev/docs/development/ui/interactive#the-parent-widget-manages-the-widgets-state
class CharacterTile extends StatelessWidget {
  final bool selected;
  final String character;
  final ValueChanged<String> onLongPress;
  final ValueChanged<String> onTap;

  CharacterTile({Key key, @required this.selected: false, @required this.character, @required this.onLongPress, @required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? Colors.grey[400] : Colors.white,
      child: ListTile(
        title: Text(character),
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        selected: selected,
      ),
    );
  }

  void _handleTap() {
    onTap(character);
  }

  void _handleLongPress() {
    onLongPress(character);
  }
}