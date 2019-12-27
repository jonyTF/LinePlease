import 'package:flutter/material.dart';
import 'package:line_please/constants.dart';
import 'package:line_please/models/script.dart';
import 'package:line_please/screens/script_details/script_details_page.dart';
import 'package:line_please/screens/script_list/script_list_page.dart';

class Router {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case scriptListRoute:
        if (args is List<Script>) {
          return MaterialPageRoute(builder: (_) => ScriptListPage(scripts: args));
        }

        // Go to Scripts page with PLACEHOLDER DATA
        return MaterialPageRoute(builder: (_) => ScriptListPage(
          scripts: List.generate(
            20,
                (i) => Script(
              'Script $i',
              i,
            )
          ),
        ));
      case scriptDetailsRoute:
        if (args is Script) {
          return MaterialPageRoute(builder: (_) => ScriptDetailsPage(script: args));
        }
        return _errorRoute(settings);
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