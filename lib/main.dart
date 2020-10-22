import 'dart:core';

import 'package:flutter/material.dart';

void main() => runApp(new BBBApp());

class BBBApp extends StatefulWidget {
  @override
  _BBBAppState createState() => new _BBBAppState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _BBBAppState extends State<BBBApp> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBB App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('BBB App'),
        ),
        body: Center(
          child: Text('To-Do!'),
        ),
      ),
    );
  }
}
