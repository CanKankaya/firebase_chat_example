import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_chat_example/widgets/alert_dialog.dart';

import 'package:firebase_chat_example/screens/chat_screen.dart';
import 'package:firebase_chat_example/screens/profile_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
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
            ),
            Expanded(
              flex: 15,
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Chat Screen'),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: const Text('Temp Listtile'),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('Temp Listtile'),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Temp Listtile'),
                    onTap: () {},
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
                    onTap: () {},
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
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_circle,
                            size: 32, color: Colors.white),
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
                            () {
                              FirebaseAuth.instance.signOut();
                              // Navigator.of(context).pop();
                              // Navigator.pushReplacement(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const AuthScreen(),
                              //   ),
                              // );
                            },
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 20),
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
