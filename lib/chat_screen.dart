import 'package:chat_ui/api_helpers.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

// class ChatScreen extends StatelessWidget {
//   const ChatScreen({Key? key}) : super(key: key);

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const ChatPage(
//         user: "alaevens",
//         receiver: "testuser",
//       ),
//     );
//   }
// }

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
    // only need to pull the history once
    loadHistory(widget.args.token, widget.args.username, widget.args.receiver)
        .then((List<List<String>> value) {
      _messageListKey.currentState!.setHistory(value);
    });

    // only need to create the socket once
    _createSocket(widget.args.token);
  }

  @override
  void dispose() {
    ws.close();
    super.dispose();
  }

  void _createSocket(String token) async {
    // form websocket connection
    WebSocket sock = await WebSocket.connect(
        BASE_WS_URL +
            "/ws/chat/${widget.args.username}/${widget.args.receiver}",
        headers: {"Authorization": "Token " + token});

    setState(() => ws = sock);

    // Set up a listener on the new socket.
    ws.listen((event) async {
      Map<String, dynamic> json = jsonDecode(event);
      String displayName = userCache[json["username"]] ?? "";

      // use the username to fetch the display name, but only when its not known
      if (displayName == "") {
        String accountID = await checkExists(json["username"]);
        displayName = await accountIdToDisplayName(accountID);
        userCache[json["username"]] = displayName;
      }

      // add the new message to the display
      _messageListKey.currentState!.addMessage(displayName, json["message"]);
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
  void addMessage(String sender, String content) {
    setState(() {
      history.add([sender, content]);
    });
  }

  // set entire history list
  void setHistory(List<List<String>> hist) {
    setState(() => history = hist);
  }

  void setDisplayName(String display) {
    setState(() => myDisplay = display);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: history.length * 2,
      itemBuilder: (context, i) {
        if (i % 2 == 0) {
          return Message(
              sender: history[i ~/ 2][0],
              content: history[i ~/ 2][1],
              me: myDisplay);
        } else {
          return const Divider();
        }
      },
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
    return Column(
      crossAxisAlignment:
          sender == me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          sender,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(content)
      ],
    );
  }
}
