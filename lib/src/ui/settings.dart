import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Settings'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: "EDA-NEW",
                decoration: InputDecoration(
                  labelText: "Device ID",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Server URL",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              TextFormField(
                initialValue: 3000.toString(),
                decoration: InputDecoration(
                  labelText: "Server PORT",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              SizedBox(height: 20),
              RaisedButton(onPressed: null, child: Text('Apply Changes'))
            ],
          ),
        ),
      ),
    );
  }
}
