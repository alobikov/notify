import 'dart:async';
import 'dart:convert';
import 'package:notify/src/models/message.dart';
import 'package:http/http.dart' as http;

class HttpService {
  bool isEda = false;
  String deviceId;

  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  ///* deletes message by it ID
  Future deleteMessage(String url, String id) async {
    final response = await http.get('http://$url/messages/deleteId/$id');
  }

  ///* creates list of users registered in socket.io
  Future<List<String>> getListOfRecipients(String url) async {
    final response = await http.get('http://$url/users');

    if (response.statusCode == 200) {
      // If the server returns 200 OK response,
      // then parse the JSON.
      final result = json.decode(response.body);

      print('Registered Socket.io users (my recipients): $result');
      return [for (var val in result) val['deviceId']];
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load users');
    }
  }

  ///* sends message by POST
  Future sendMessage(url, body, to, from) async {
    final bodyJson = jsonEncode({'message': body, 'to': to, "from": from});
    try {
      final response = await http.post('http://$url/message',
          headers: {"Content-Type": "application/json"}, body: bodyJson);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print(e);
    }
  }

  ///* reads user messages from backend by GET
  Future retrieveUserMessages(
      Messages _msg, String url, String username) async {
    final response = await http
        .get('http://$url/messages/$username')
        .timeout(Duration(seconds: 2), onTimeout: () {
      print("response to get request is too long!");
      return null;
    });

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      print("retrieveUserMessages(): $result");
      _msg.messages.clear(); // delete all locally stored messages
      for (var message in result) {
        _msg.messages.insert(
            0,
            NotyMessage(
                body: message['message'],
                from: message['from'],
                objectId: message['_id'].toString(),
                timestamp: message['timestamp'].toString() ?? ''));
      }
    }

    return null;
  }
}
