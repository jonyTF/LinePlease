import 'package:flutter/material.dart';
import 'package:line_please/constants.dart';
import 'package:line_please/models/script.dart';
import 'package:line_please/models/scene.dart';
import 'package:line_please/screens/character_select/character_select_page.dart';
import 'package:line_please/screens/scene_details/scene_details_page.dart';
import 'package:line_please/screens/script_list/script_list_page.dart';
import 'package:line_please/screens/scene_list/scene_list_page.dart';


class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case scriptListRoute:
        // TODO: Replace with real data
        // Go to Scripts page with PLACEHOLDER DATA
        return MaterialPageRoute(builder: (_) => ScriptListPage(
          scripts: List.generate(
            20,
            (i) => Script(
              title: 'Script $i',
            )
          ),
        ));
      case sceneListRoute:
        final script = args as Script;
        return MaterialPageRoute(builder: (_) => SceneListPage(script: script));
      case sceneDetailsRoute:
        final scene = args as Scene;
        return MaterialPageRoute(builder: (_) => SceneDetailsPage(scene: scene));
      case characterSelectRoute:
        final characters = args as List<String>;
        print('CHARACTERS: $characters');
        return MaterialPageRoute(builder: (_) => CharacterSelectPage(characters: characters));
      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('ERROR when trying to access ${settings.name}'),
        ),
      );
    });
  }
}