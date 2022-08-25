import 'package:firebase_chat_example/screens/private_chats_list_screen.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:firebase_chat_example/providers/theme_provider.dart';

import 'package:firebase_chat_example/widgets/alert_dialog.dart';

import 'package:firebase_chat_example/screens/profile/profile_screen.dart';
import 'package:firebase_chat_example/screens/public_chats_list_screen.dart';
import 'package:firebase_chat_example/screens/audio_screen.dart';
import 'package:firebase_chat_example/screens/auth_screen.dart';
import 'package:firebase_chat_example/screens/test_screen.dart';
import 'package:firebase_chat_example/screens/map_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.amber,
      ),
      child: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text('Drawer\'s title'),
              automaticallyImplyLeading: false,
              actions: [
                Consumer<ThemeModel>(
                  builder: (context, ThemeModel themeNotifier, __) {
                    return IconButton(
                      onPressed: () {
                        themeNotifier.isDark
                            ? themeNotifier.isDark = false
                            : themeNotifier.isDark = true;
                      },
                      icon: Icon(
                        themeNotifier.isDark ? Icons.dark_mode : Icons.light_mode,
                      ),
                    );
                  },
                )
              ],
            ),
            Expanded(
              flex: 15,
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Public Chats'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PublicChatsListScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('Private Chats'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivateChatsListScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.audiotrack),
                    title: const Text('Audio Test Page'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AudioScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.map),
                    title: const Text('Map Test Page'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.build,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                    title: Text(
                      'A Pointless and Extra Long Listtile for Debugging Purposes',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.build,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                    title: Text(
                      'Another, Also Pointless and Even Longer Listtile for More Debugging Purposes',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.build,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                    title: Text(
                      'More Pointless Listtiles',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.build,
                      color: Colors.grey.withOpacity(0.6),
                    ),
                    title: Text(
                      'These Listtiles are only here for debugging -_-',
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.construction,
                    ),
                    title: const Text('Go to Test Page'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_circle, size: 32, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextButton(
                        onPressed: () {
                          showMyDialog(
                            context,
                            true,
                            'Logout',
                            'Are you sure you want to logout?',
                            '',
                            'Yes',
                            () async {
                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AuthScreen(),
                                  ));
                              FirebaseAuth.instance.signOut();
                            },
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 20, color: Colors.amber),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
