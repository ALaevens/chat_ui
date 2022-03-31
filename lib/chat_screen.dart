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
    loadHistory(widget.args.token, widget.args.username, widget.args.receiver)
        .then((List<List<String>> value) {
      _messageListKey.currentState!.setHistory(value);
    });

    _createSocket(widget.args.token);
  }

  void _createSocket(String token) async {
    WebSocket sock = await WebSocket.connect(
        BASE_WS_URL +
            "/ws/chat/${widget.args.username}/${widget.args.receiver}",
        headers: {"Authorization": "Token " + token});

    setState(() => ws = sock);

    ws.listen((event) async {
      Map<String, dynamic> json = jsonDecode(event);
      String displayName = userCache[json["username"]] ?? "";

      if (displayName == "") {
        String accountID = await checkExists(json["username"]);
        displayName = await accountIdToDisplayName(accountID);
        userCache[json["username"]] = displayName;
      }

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
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _entryController,
                  ),
                )),
                TextButton(
                    onPressed: () {
                      ws.add(jsonEncode({"message": _entryController.text}));
                      _entryController.clear();
                    },
                    child: const Text("SEND"))
              ],
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

class _MessageWindowState extends State<MessageWindow> {
  List<List<String>> history = [];

  void addMessage(String sender, String content) {
    setState(() {
      history.add([sender, content]);
    });
  }

  void setHistory(List<List<String>> hist) {
    setState(() => history = hist);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: history.length * 2,
      itemBuilder: (context, i) {
        if (i % 2 == 0) {
          return Message(
              sender: history[i ~/ 2][0], content: history[i ~/ 2][1]);
        } else {
          return const Divider();
        }
      },
    );
  }
}

class Message extends StatelessWidget {
  const Message({Key? key, required this.sender, required this.content})
      : super(key: key);

  final String sender;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              sender,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(content),
          ),
        )
      ],
    );
  }
}
