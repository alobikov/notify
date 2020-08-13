import 'dart:async';
import 'package:device_id/device_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notify/src/models/addressees.dart';
import 'package:notify/src/models/error_handler.dart';
import 'package:notify/src/models/message.dart';
import 'package:notify/src/models/self_Config.dart';
import 'package:notify/src/services/http_service.dart';
import 'package:notify/src/services/socketio.dart';
import 'package:notify/utils/connection_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info/device_info.dart';
// import 'package:notify/src/services/create_object.dart';

part 'register_event.dart';
part 'register_state.dart';

enum AppState {
  uninitialized,
  authenticated,
  unauthenticated,
  unregistred,
  sendMessageForm,
  loading,
  error,
  reset,
  firstlaunch,
}
enum UIState {
  home,
  messageSendForm,
  loading,
  signin,
  zero,
  alertScreen,
  introduce,
  settings,
}

class RegisterBloc extends ChangeNotifier {
  final _msg = Messages.instance;
  // final _msgToSend = MessageToSend();
  final _http = HttpService();
  final _addressees = Addressees();
  final _errorHandler = ErrorHandler.instance;
  final registerFormFields;
  RegisterInitFields initFields;
  UIState uiState;
  var _liveQuery;
  bool showRegister = true;
  bool showHome = false;
  String emailError;
  bool isOffline = false;
  final selfConfig =
      SelfConfig(deviceName: "", serverUrl: '192.168.1.60', port: '3000');

  StreamSubscription _connectionChangeStream;

  ConnectionStatusSingleton connectionStatus =
      ConnectionStatusSingleton.getInstance();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  StreamController _appStateCtrl = StreamController<AppState>();
  Stream<AppState> get appState => _appStateCtrl.stream;
  StreamSink<AppState> get _inState => _appStateCtrl.sink;

  StreamController _initFormStateCtrl = StreamController<String>.broadcast();
  Stream<String> get initiateState => _initFormStateCtrl.stream;
  StreamSink<String> get initiateForm => _initFormStateCtrl.sink;

  StreamController _regFormStateCtrl = StreamController<Map<String, dynamic>>();
  Stream<Map<String, dynamic>> get formState => _regFormStateCtrl.stream;
  StreamSink<Map<String, dynamic>> get inForm => _regFormStateCtrl.sink;

  StreamController _regFormEventCtrl = StreamController<RegisterEvent>();
  StreamSink<RegisterEvent> get event => _regFormEventCtrl.sink;

  RegisterFormFields get getFormFields => registerFormFields;
  SelfConfig get getSelfConfig => selfConfig;

  // ! Register Bloc constructor
  RegisterBloc() : registerFormFields = RegisterFormFields() {
    print('!!!!!!!  Register block constructor invoked !!!!!!!!!');

    _regFormEventCtrl.stream.listen(_mapEventController);

    /// this stream is used to inform about internet connectivity changes
    _connectionChangeStream =
        connectionStatus.connectionChange.listen(connectionChanged);

    /// this stream used to receive data from TextFormFields
    formState.listen((form) {
      print('formState in Bloc received: $form');
      registerFormFields.setField(form);
      print('Current state of RegFormFields ${registerFormFields.show()}');
    });
  }

  void _mapEventController(event) async {
    //***************************************/
    //* Populate Register/Signin form by mock user date
    if (event is SendMessageFormEvent) {
      String deviceid = await DeviceId.getID;
      print('^^^^^^^^^^^^^^^^^^^^^^ DeviceID: $deviceid');
      // await _b4a.getAllUsers();
      _inState.add(AppState.sendMessageForm);
      return;
      //
      //***************************************/
      //* SignOut event handler
    } else if (event is UserLogoutEvent) {
      _inState.add(AppState.loading);
      initData(); // show Signin()
      return;

      //**************************************/
      //* toggle Register UI to Signin UI
    } else if (event is SwitchToSigninEvent) {
      _inState.add(AppState.unauthenticated);
      return;
    } else if (event is SwitchToRegisterEvent) {
      _inState.add(AppState.unregistred);
      return;
      //
      //**************************************/
      //* Application Initializing
    } else if (event is InitializeApp) {
      print('Register Bloc: Application Initializing');
      initData();
      return;

      //**************************************/
      //* New Message from server receive handling
    } else if (event is NewMessage) {
      //!  duplicated
      print('RegisterBloc: New message event');
      String title = 'From: ${event.msg.from} @ ${event.msg.timestamp}';
      await _showNotification(title, event.msg.body);
      _inState.add(AppState.authenticated); // redraw Home() with new message
      return;

      //**************************************/
      //* Return to Home Screen event handling
    } else if (event is NavigateToHomeEvent) {
      _inState.add(AppState.authenticated);
    }
    return;
  }

  String getFormFieldFor(String field) {
    return registerFormFields.getField(field);
  }

  initData() async {
    // check the hosting device - must be scanner Honeywell
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    print('Running on ${androidInfo.model}');
    if (androidInfo.model != 'EDA60K') {
      print("THIS PROGRAM MUST BE RUN ON EDA60K SCANNER");
      // TODO - route to nowhere
    }

    // is it first launch of application?
    final prefs = await SharedPreferences.getInstance();
    print('initData() deviceName ${prefs.getString("deviceName")}');
    selfConfig
      ..deviceName = prefs.getString('deviceName') ?? ''
      ..serverUrl = prefs.getString('serverUrl') ?? '192.168.0.14'
      ..port = prefs.getString('port') ?? '3000';

    if (selfConfig.deviceName == '') {
      _inState.add(AppState.firstlaunch);
      print("First Launch!!!!!!!!!!!!!!!!!!!!!!!!");
      return;
    }
    // continue initialization if device confiugured
    final ws = SocketIoService();
    ws.initialize(
        selfConfig: selfConfig, msg: _msg, sink: _regFormEventCtrl.sink);
    print('After ws.initialize()');
    //* initializing of LocalNotification service
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    bool res = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: onSelectNotification);

    //* initializing Back4App service
    // await Future.delayed(Duration(seconds: 1));
    // await _b4a.initParse();

    // initialize connection status watch dog
    // external library
    // used to handle internet connection status change
    connectionStatus.initialize();

    //* check for user status on Back4App
    // var result = await _b4a.isLogged();
    // if (result != null) {
    //   print('---------------------$result');
    //   // initialize RegisterFormFields since user is active in b4a
    //   registerFormFields.setField(result);
    //   // if (!_b4a.isEda) {
    //* read from server all messages addressed for this user
    await _initMessageHandler();
    print('after message handler');
    event.add(NavigateToHomeEvent());
    //* built list of contacts
//    await _b4a.getAddressees(_addressees);
    return;
  }

  Future _initMessageHandler() async {
    print('InitMessageHandler()');
    try {
      await _http.retrieveUserMessages(
        _msg,
        selfConfig.serverUrl + ':' + selfConfig.port,
        selfConfig.deviceName,
      );
    } catch (e) {
      print('can not read messages');
    }

    print('Message read completed');
    return null;
  }

  Future onSelectNotification(String payload) async {
    Future.delayed(Duration(seconds: 5));
    print('onSelect Notification invoked');
    // showDialog(
    //     context: context,
    //     builder: (_) => AlertDialog(
    //         title: const Text('New message received'),
    //         content: Text('payload')));
  }

  Future _showNotification(title, body) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }

  void connectionChanged(dynamic hasConnection) async {
    isOffline = !hasConnection;
    if (!isOffline) {
      print('*****connection restored******');
      print(uiState);
    } else {
      print('@@@@@@@@@ Inetrnet lost @@@@@@@@@');
      print(uiState);
    }
  }

  checkOnNetworkTimeout() {
    if (uiState == UIState.loading) {
      _errorHandler.revertEvent = SwitchToSigninEvent();
      _errorHandler.message =
          "Network connection to slow or lost, please try again later.";
      _inState.add(AppState.error);
      uiState = UIState.zero;
    }
  }

  void dispose() {
    super.dispose();
    print("*********** Dispose in RegisterBloc ***************");
    _appStateCtrl.close();
    _regFormStateCtrl.close();
    _regFormEventCtrl.close();
    _initFormStateCtrl.close();
    connectionStatus.dispose();
  }
}
