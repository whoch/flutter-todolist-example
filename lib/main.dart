import 'package:flare_splash_screen/flare_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:todolist/todo_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen.navigate(
        name: 'intro.flr',
        next: (_) => TodoScreen(),
        until: () => Future.delayed(Duration(seconds: 5)),
        startAnimation: '1',
      ),
    );
  }
}
