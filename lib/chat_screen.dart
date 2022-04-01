import 'package:chat_ui/api_helpers.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class ChatArguments {
  final String username;
  final String token;
  final String receiver;

  ChatArguments(this.username, this.token, this.receiver);
}

class ChatPage extends StatefulWidget {
  final ChatArguments args;
  const ChatPage({Key? key, required this.args}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _entryController = TextEditingController();
  final GlobalKey<_MessageWindowState> _messageListKey = GlobalKey();

  Map<String, String> userCache = {};

  late WebSocket ws;

  @override
  void initState() {
    super.initState();

    usernameToDisplayName(widget.args.username).then((value) {
      _messageListKey.currentState!.setDisplayName(value);
    });

    getRoomByUser(widget.args.token, widget.args.username, widget.args.receiver)
        .then((Map<String, dynamic> value) {
      _messageListKey.currentState!.setHistory(value["history"]);

      _createSocket(widget.args.token, value["room_id"]);
    });
  }

  @override
  void dispose() {
    ws.close();
    super.dispose();
  }

  void _createSocket(String token, String room) async {
    // form websocket connection
    WebSocket sock = await WebSocket.connect(BASE_WS_URL + "/ws/chat/$room",
        headers: {"Authorization": "Token " + token});

    setState(() => ws = sock);

    // Set up a listener on the new socket.
    ws.listen((event) async {
      print(event);
      Map<String, dynamic> json = jsonDecode(event);
      String accountID = json["account_id"];
      String displayName = userCache[json["account_id"]] ?? "";

      // only request display name if absolutely necessary
      if (displayName == "") {
        displayName = await accountIdToDisplayName(accountID);
        userCache[accountID] = displayName;
      }

      // add the new message to the display
      _messageListKey.currentState!
          .addMessage([accountID, displayName, json["message"]]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messaging"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: Padding(
              child: MessageWindow(key: _messageListKey),
              padding: const EdgeInsets.all(8),
            )),
            Container(
              color: Colors.grey[300],
              child: Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                        controller: _entryController,
                        style: const TextStyle(fontSize: 16),
                        keyboardType: TextInputType.multiline,
                        maxLines: null),
                  )),
                  IconButton(
                      onPressed: () {
                        // once the send button is clicked, send the text to the websocket
                        ws.add(jsonEncode({"message": _entryController.text}));
                        _entryController.clear();
                      },
                      icon: const Icon(Icons.send, size: 32))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MessageWindow extends StatefulWidget {
  const MessageWindow({Key? key}) : super(key: key);

  @override
  State<MessageWindow> createState() => _MessageWindowState();
}

// Window containing all sent / received messages
class _MessageWindowState extends State<MessageWindow> {
  List<List<String>> history = [];
  String myDisplay = "";

  // add one to history
  void addMessage(List<String> row) {
    setState(() {
      if (history.isNotEmpty && history.last[0] == row[0]) {
        history.last[2] += "\n" + row[2];
      } else {
        history.add(row);
      }
    });
  }

  // set entire history list
  void setHistory(List<List<String>> hist) {
    List<List<String>> tempHistory = [];
    for (List<String> row in hist) {
      if (tempHistory.isNotEmpty && tempHistory.last[0] == row[0]) {
        // if account id matches, append message instead
        tempHistory.last[2] += "\n" + row[2];
      } else {
        tempHistory.add(row);
      }
    }
    setState(() => history = tempHistory);
  }

  void setDisplayName(String display) {
    setState(() => myDisplay = display);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: history.length,
      itemBuilder: (context, i) {
        return Message(
            sender: history[i][1], content: history[i][2], me: myDisplay);
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}

// A Row in view of sent / received messages
class Message extends StatelessWidget {
  const Message(
      {Key? key, required this.sender, required this.content, required this.me})
      : super(key: key);

  final String sender;
  final String content;
  final String me;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: sender == me ? Colors.blue[100] : Colors.green[100],
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment:
              sender == me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              content,
              textAlign: sender == me ? TextAlign.right : TextAlign.left,
            )
          ],
        ),
      ),
    );
  }
}
