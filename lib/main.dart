import 'package:firebase_chat_example/providers/following_provider.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:firebase_chat_example/providers/add_participant_provider.dart';
import 'package:firebase_chat_example/providers/reply_provider.dart';
import 'package:firebase_chat_example/providers/theme_provider.dart';

import 'package:firebase_chat_example/screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => ReplyProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => AddListProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => FollowingProvider(),
        ),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, ThemeModel themeNotifier, __) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: themeNotifier.isDark ? ThemeData.dark() : ThemeData.light(),
            home: AuthScreen(),
          );
        },
      ),
    );
  }
}
