import 'package:async/async.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String BASE_URL = "https://latandao.gearnotes2000.xyz";
const String BASE_WS_URL = "wss://latandao.gearnotes2000.xyz";

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

Future<String> usernameToDisplayName(String username) async {
  String accountID = await checkExists(username);

  if (accountID == "") {
    return "";
  }

  String displayName = await accountIdToDisplayName(accountID);

  return displayName;
}

Future<Map<String, dynamic>> getRoom(http.Response response) async {
  if (response.statusCode == 200) {
    Map<String, String> idCache = {};
    Map<String, dynamic> json = jsonDecode(response.body);
    var messages = json["messages"];
    var room_id = json["room_id"];
    List<List<String>> history = [];

    for (Map<String, dynamic> messageRow in messages) {
      String accountID = messageRow["owner"];
      String display = idCache[accountID] ?? "";

      // only get display name if absolutely necessary
      if (display == "") {
        display = await accountIdToDisplayName(accountID);
        idCache[accountID] = display;
      }

      history.add([accountID, display, messageRow["message"]]);
    }

    return {"room_id": room_id, "history": history};
  } else {
    return {};
  }
}

Future<Map<String, dynamic>> getRoomByUser(
    String loginToken, String user1, String user2) async {
  final String REQUEST_URL = BASE_URL + "/chat/users/$user1/$user2/";

  final http.Response response =
      await http.get(Uri.parse(REQUEST_URL), headers: {
    HttpHeaders.authorizationHeader: "Token $loginToken",
  });

  return getRoom(response);
}

Future<Map<String, dynamic>> getRoomByAccount(
    String loginToken, String account1, String account2) async {
  final String REQUEST_URL = BASE_URL + "/chat/accounts/$account1/$account2/";

  final http.Response response =
      await http.get(Uri.parse(REQUEST_URL), headers: {
    HttpHeaders.authorizationHeader: "Token $loginToken",
  });

  return getRoom(response);
}
