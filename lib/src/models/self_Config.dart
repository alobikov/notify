import 'package:flutter/material.dart';

class SelfConfig extends ChangeNotifier {
  String deviceName;
  String serverUrl;
  String port;

  SelfConfig({this.deviceName, this.serverUrl, this.port});
}
