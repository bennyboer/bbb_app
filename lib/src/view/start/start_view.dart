import 'package:flutter/material.dart';

import 'file:///C:/repo/bbb_app/lib/src/view/main/main_view.dart';

// Start view of the app where you'll be able to enter a meeting using the invitation link.
class StartView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StartViewState();
}

/// State of the start view.
class _StartViewState extends State<StartView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text("Login"),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainView()),
            );
          },
        ),
      ),
    );
  }
}
