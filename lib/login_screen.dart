import 'package:chat_ui/chat_screen.dart';
import 'package:flutter/material.dart';
import 'api_helpers.dart';

// class LoginScreen extends StatelessWidget {
//   const LoginScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Login',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const LoginPage(),
//     );
//   }
// }

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login to Latandao"),
      ),
      body: const Center(
          child: FractionallySizedBox(
        widthFactor: 0.6,
        child: Card(
            child: Padding(padding: EdgeInsets.all(8), child: LoginForm())),
      )),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _receiverController = TextEditingController();

  void tryLogIn() async {
    String uName = _usernameController.text;
    String password = _passwordController.text;
    String receiver = _receiverController.text;

    if (await checkExists(uName) == "") {
      showError("User with that name does not exist");
      return;
    }

    String tok = await login(uName, password);

    if (tok == "") {
      showError("Incorrect password");
      return;
    }

    if (await checkExists(receiver) == "") {
      showError("Contact with that name does not exist");
      return;
    }

    Navigator.pushNamed(context, "/chat",
        arguments: ChatArguments(uName, tok, receiver));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      onChanged: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Login', style: Theme.of(context).textTheme.headline4),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(hintText: 'Username'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _passwordController,
              obscureText: true,
              obscuringCharacter: "*",
              decoration: const InputDecoration(hintText: 'Password'),
            ),
          ),
          const Divider(thickness: 4),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _receiverController,
              decoration: const InputDecoration(hintText: 'Connect With'),
            ),
          ),
          const Divider(thickness: 4),
          TextButton(
              style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                return states.contains(MaterialState.disabled)
                    ? null
                    : Colors.white;
              }), backgroundColor: MaterialStateProperty.resolveWith((states) {
                return states.contains(MaterialState.disabled)
                    ? null
                    : Colors.blue;
              })),
              child: const Text("Login"),
              onPressed: () => tryLogIn())
        ],
      ),
    );
  }

  void showError(String errorText) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(errorText),
      action: SnackBarAction(
          label: "Dismiss",
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar()),
    ));
  }
}
