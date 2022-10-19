import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _control = PerfectVolumeControl();

  TextEditingController _textEditingController = TextEditingController();

  StreamSubscription<double> _subscription;

  @override
  void initState() {
    super.initState();
    // Bind listener
    _subscription = _control.stream.listen((value) {
      _textEditingController.text = "listener: $value";
    });
    _control.startListeningVolume();
  }

  @override
  void dispose() {
    super.dispose();

    // Remove listener
    _subscription.cancel();
    _textEditingController.dispose();
    _control.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(controller: _textEditingController),
                Container(height: 10),
                Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        child: Text("hideUI"),
                        onPressed: () async {
                          await _control.hideUI(true);
                          _textEditingController.text = "hideUI finish";
                        },
                      ),
                      OutlinedButton(
                        child: Text("showUI"),
                        onPressed: () async {
                          await _control.hideUI(false);
                          _textEditingController.text = "showUI finish";
                        },
                      ),
                      OutlinedButton(
                        child: Text("getVolume"),
                        onPressed: () async {
                          double volume = await _control.getVolume();
                          _textEditingController.text = "$volume";
                        },
                      ),
                      OutlinedButton(
                        child: Text("mute"),
                        onPressed: () async {
                          await _control.setVolume(0);
                          _textEditingController.text = "mute finish";
                        },
                      ),
                      OutlinedButton(
                        child: Text("setVolume to 0.3"),
                        onPressed: () async {
                          await _control.setVolume(0.3);
                          _textEditingController.text =
                              "setVolume to 0.3 finish";
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
