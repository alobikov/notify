import 'package:flutter/material.dart';
import 'package:notify/main.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/models/self_Config.dart';
import 'package:notify/src/services/socketio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  Settings({Key key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _ws = SocketIoService();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final _bloc = Provider.of<RegisterBloc>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('System Settings'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  initialValue: _bloc.selfConfig.deviceName,
                  decoration: InputDecoration(
                    labelText: "Device ID",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onSaved: (val) =>
                      setState(() => _bloc.selfConfig.deviceName = val),
                ),
                TextFormField(
                  initialValue: _bloc.selfConfig.serverUrl,
                  decoration: InputDecoration(
                    labelText: "Server URL",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onSaved: (val) =>
                      setState(() => _bloc.selfConfig.serverUrl = val),
                ),
                TextFormField(
                  initialValue: _bloc.selfConfig.port,
                  decoration: InputDecoration(
                    labelText: "Server PORT",
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onSaved: (val) => setState(() => _bloc.selfConfig.port = val),
                ),
                SizedBox(height: 20),
                RaisedButton(
                    color: Colors.teal,
                    onPressed: () {
                      final form = _formKey.currentState;
                      form.save();
                      saveConfig(_bloc.selfConfig);
                      _ws.socket?.emit('disconnect');
                      print('emitting "disconnect"');
                      Future.delayed(
                          Duration(seconds: 1),
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => InitApp())));
                    },
                    child: Text('Apply Changes'))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void saveConfig(SelfConfig selfConfig) async {
    final prefs = await SharedPreferences.getInstance();
    prefs
      ..setString('deviceName', selfConfig.deviceName)
      ..setString('serverUrl', selfConfig.serverUrl)
      ..setString('port', selfConfig.port);
  }
}
