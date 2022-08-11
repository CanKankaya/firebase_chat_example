import 'package:firebase_chat_example/screens/splash_screen.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_chat_example/screens/auth_screen.dart';
import 'package:firebase_chat_example/screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.none) {
              return const SplashScreen();
            } else {
              return snapshot.hasData ? const ChatScreen() : const AuthScreen();
            }
          }),
      routes: {
        //
        AuthScreen.routeName: (ctx) => const AuthScreen(),
      },
    );
  }
}
