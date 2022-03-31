import 'chat_screen.dart';
import 'login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Latandao Chat",
    initialRoute: "/login",
    onGenerateRoute: (RouteSettings settings) {
      print('build route for ${settings.name}');
      var routes = <String, WidgetBuilder>{
        "/chat": (ctx) => ChatPage(args: settings.arguments as ChatArguments),
        "/login": (ctx) => LoginPage(),
      };
      WidgetBuilder? builder = routes[settings.name];
      if (builder != null) {
        return MaterialPageRoute(builder: (ctx) => builder(ctx));
      } else {}
    },
  ));
}
