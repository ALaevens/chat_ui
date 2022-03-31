import 'package:async/async.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String BASE_URL = "https://gearnotes2000.xyz";
const String BASE_WS_URL = "wss://gearnotes2000.xyz";

Future<String> login(String username, String password) async {
  const String REQUEST_URL = BASE_URL + "/auth/token";

  final http.Response response = await http.post(Uri.parse(REQUEST_URL),
      body: {"username": username, "password": password});

  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    return json["token"];
  } else {
    return "";
  }
}

Future<String> checkExists(String username) async {
  const String REQUEST_URL = BASE_URL + "/auth/users/exists";

  final http.Response response =
      await http.post(Uri.parse(REQUEST_URL), body: {"username": username});

  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    if (json["business"] != null) {
      return json["business"];
    } else if (json["customer"] != null) {
      return json["customer"];
    } else {
      return "";
    }
  } else {
    return "";
  }
}

Future<String> accountIdToDisplayName(String id) async {
  String REQUEST_URL = BASE_URL + "/api/accounts/$id";

  final http.Response response = await http.get(Uri.parse(REQUEST_URL));

  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    return json["displayName"];
  } else {
    return "";
  }
}

Future<List<List<String>>> loadHistory(
    String loginToken, String user1, String user2) async {
  final String REQUEST_URL = BASE_URL + "/chat/$user1/$user2/";

  final http.Response response =
      await http.get(Uri.parse(REQUEST_URL), headers: {
    HttpHeaders.authorizationHeader: "Token $loginToken",
  });
  Map<String, String> userCache = {};

  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    var messages = json["messages"];
    List<List<String>> history = [];

    for (Map<String, dynamic> messageRow in messages) {
      String userID = messageRow["owner"];
      String display = userCache[userID] ?? "";

      // only get display name if absolutely necessary
      if (display == "") {
        display = await accountIdToDisplayName(userID);
        userCache[userID] = display;
      }

      history.add([display, messageRow["message"]]);
    }

    return history;
  } else {
    return [];
  }
}

// void main(List<String> arguments) async {
//   // LOGIN
//   stdout.write("Login:\n  username: ");
//   String username = stdin.readLineSync() ?? "";

//   stdout.write("  Password: ");
//   String password = stdin.readLineSync() ?? "";

//   if (username == "" || password == "") {
//     return;
//   } else {
//     username = username.toString();
//     password = password.toString();
//   }

//   String tok = await login(username, password);

//   // GET RECIPIENT AND MAKE SURE THEY EXIST
//   stdout.write("Send message to (username): ");
//   var receivename = stdin.readLineSync() ?? "";
//   var exists = await checkExists(receivename);

//   if (exists == "") {
//     return;
//   }

//   // LOAD HISTORY
//   List<dynamic> hist = await loadHistory(tok, username, receivename);
//   print("History: ");
//   hist.forEach((element) {
//     print(element[0] + ": " + element[1]);
//   });

//   // SOCKET CONNECTION
//   final sock = await WebSocket.connect(
//       BASE_WS_URL + "/ws/chat/$username/$receivename",
//       headers: {"Authorization": "Token " + tok});

//   Map<String, String> userCache = {};

//   // on recieve
//   sock.listen((event) async {
//     Map<String, dynamic> json = jsonDecode(event);
//     String displayName = userCache[json["username"]] ?? "";

//     // only request display name if absolutely necessary
//     if (displayName == "") {
//       String accountID = await checkExists(json["username"]);
//       displayName = await accountIdToDisplayName(accountID);
//       userCache[json["username"]] = displayName;
//     }

//     print(displayName + ": " + json['message']);
//   });

//   // on send
//   stdin.listen((event) {
//     String message = utf8.decode(event).trim();
//     sock.add(json.encode({"message": message}));
//   });
// }
