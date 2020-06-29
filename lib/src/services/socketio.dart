import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notify/src/blocs/register/register_bloc.dart';
import 'package:notify/src/models/message.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketIoService {
  IO.Socket socket;
  String name;
  Messages msg;
  StreamSink sink;

  static final SocketIoService _singleton = new SocketIoService._internal();

  factory SocketIoService({String name, Messages msg, StreamSink sink}) {
    _singleton.name = name;
    _singleton.msg = msg;
    _singleton.sink = sink;

    return _singleton;
  }

  SocketIoService._internal() {
    // init logic goes here
    print('SocketIoService._internal()'
        ''
        ' here!');
    socket = IO.io('http://192.168.1.61:3000', <String, dynamic>{
      'transports': ['websocket'],
    });
    print(socket.opts);
    socket.on('connect', (_) => {socket.emit('new-user', 'EDA-EMUL')});
    socket.on('event', (data) => print(data));
    socket.on('disconnect', (_) => print('disconnect'));
    socket.on('connect_error', (e) {
      print('socket connection error: $e');
    });
    socket.on('message', (msg) {
      print('Message received1: $msg');
      print('all messages ${this.msg.messages}');
//      Map<String, dynamic> m = jsonDecode(msg);
      NotyMessage notyMessage = NotyMessage(
        body: msg['message'],
        from: msg['from'],
        timestamp: msg['timestamp'].toString(),
        objectId: '234234',
      );
      this.msg.messages.insert(0, notyMessage);
      print(this.msg.messages);
      sink.add(NewMessage(notyMessage));
    });
  }

  void emitMessage(msg, to, from) {
    this.socket.emit('send-message', {'message': msg, 'to': to, 'from': from});
    print('send-message invoked $msg');
  }
//  socket.on("user-connected", (data) => {print('$data connects to the chat!')});
//  socket.on('fromServer', (_) => print(_));
}

//NotyMessage msg = NotyMessage(
//    body: (value as ParseObject).get('body'),
//    from: (value as ParseObject).get('from'),
//    objectId: (value as ParseObject).get('objectId'),
//    timestamp: (value as ParseObject).get('timestamp') ?? '2020-03-12');
//_msg.messages.insert(0, msg); //* add new message into the top of the list
//sink.add(NewMessage(
//msg)); //* Notify RegisterBlock about new message and pass the message instance
//});
