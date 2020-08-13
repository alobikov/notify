import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notify/src/models/message.dart';
import 'package:notify/src/services/http_service.dart';
import 'package:notify/src/services/socketio.dart';

// builds view of incoming messages
// messages are being stroed in Messages singleton instance
// in propierty - List<NotyMessage> messages

// TODO message delete on long press

class MsgList extends StatefulWidget {
  @override
  _MsgListState createState() => _MsgListState();
}

class _MsgListState extends State<MsgList> {
  final Messages _msg = Messages.instance;
  final HttpService _http = HttpService();
  final SocketIoService _ws = SocketIoService();

  @override
  initState() {
    super.initState();
    print("MsgList Widget - Number of messages: ${_msg.messages?.length}");
  }

  @override
  Widget build(BuildContext context) {
    // final brews = Provider.of<List<Brew>>(context) ?? [];

    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
              color: Color(0xFF167F67),
            ),
        padding: const EdgeInsets.all(1.0),
        itemCount: null == _msg.messages ? 0 : _msg.messages.length,
        itemBuilder: /*1*/ (context, i) {
          return _buildRow(_msg.messages[i]);
        });
  }

  Widget _buildRow(NotyMessage message) {
    // prepare correct date and time
    String msgDate, msgTime;
    final val = int.tryParse(message.timestamp);
    if (val == null) {
      // if timestamp not converts to int then check timestamp to be in old style
      if (message.timestamp.contains(" ")) {
        // old style timestamp - formated date and time string
        msgDate = message.timestamp;
        msgTime = '';
      } else {
        msgDate = 'No Date';
        msgTime = '';
      }
    } else {
      final timeStamp = new DateTime.fromMillisecondsSinceEpoch(val);
      msgDate = DateFormat('yyyy-MM-dd').format(timeStamp);
      msgTime = DateFormat.Hm().format(timeStamp);
    }

    return ListTile(
      onLongPress: () async {
        final bool action = await _deleteConfirmAlert(context);
        if (action) {
          setState(() {
            var id = message.objectId;
            print(id);
            _msg.deleteMessageLocallyById(id);
            _http.deleteMessage(_ws.url, id);
          });
        }
      },
      title: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                child: Text(
                  'from: ${message.from}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Spacer(),
              Container(
                child: Text(
                  '$msgDate $msgTime',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                // formatDate(message.timestamp, dateformat).toString()),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  message.body ?? 'null',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<bool> _deleteConfirmAlert(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete message!'),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
