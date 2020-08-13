import 'package:flutter/material.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/models/self_Config.dart';
import 'package:provider/provider.dart';

class ProfileInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final SelfConfig user =
        Provider.of<RegisterBloc>(context, listen: false).getSelfConfig;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Profile',
        ),
      ),
      body: Container(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Device information', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10.0),
              Text('Server address: ${user.serverUrl}'),
              Text('Server port: ${user.port}'),
              Text('Device ID: ${user.deviceName}'),
            ],
          )),
    );
  }
}
