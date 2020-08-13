import 'dart:async';
import 'package:notify/src/services/http_service.dart';
import 'package:notify/src/services/socketio.dart';

enum FormAction { cancel, submit }

class SendMessageBloc {
  final _http = HttpService();
  final _ws = SocketIoService();

// stream for action and message deliuvery from SendForm to Bloc
  StreamController _formCtrl = StreamController();
  Stream get _formState => _formCtrl.stream;
  StreamSink get inForm => _formCtrl.sink;

// stream to deliver list for DropDown menu of addressees
  StreamController _menuCtrl = StreamController<List<String>>();
  Stream<List<String>> get menuList => _menuCtrl.stream;
  StreamSink<List<String>> get _inMenuList => _menuCtrl.sink;

  SendMessageBloc() {
    // request list of addressees from Back4App and stream out to view for DropDown Menu
    _http
        .getListOfRecipients(_ws.url)
        .then((List<String> data) => _inMenuList.add(data));
    _formState.listen(_mapEvents);
  }
  _mapEvents(event) async {
    print('Event from SendForm');
    print(event.action);
    if (event.action == FormAction.cancel) {
      // print('Cancel');
      // event.fun(NavigateToHomeEvent());
    } else if (event.action == FormAction.submit) {
      await _http.sendMessage(_ws.url, event.body, event.to, event.from);
      return;
    }
  }

  void dispose() {
    print('*** SendMessageBloc dispose() invoked ***');
    _formCtrl.close();
    _menuCtrl.close();
  }
}

class SendMsgAction {
  final FormAction action;
  final String body;
  final String to;
  final String from;
  var fun;

  SendMsgAction({this.action, this.body, this.to, this.from, this.fun});
}
