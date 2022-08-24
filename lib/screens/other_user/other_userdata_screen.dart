import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/screens/other_user/otheruser_followers_screen.dart';
import 'package:firebase_chat_example/screens/other_user/otheruser_following_screen.dart';

class OtherUserDataScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Object?>? user;

  const OtherUserDataScreen({super.key, required this.user});
//TODO: add a follow/unfollow button here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(
                              user?['userImageUrl'] ?? '',
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user?['username'] ?? '',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserFollowingScreen(thisUser: user),
                                ),
                              );
                            },
                            child: Text(
                              '${(user?['followingCount'] ?? 0).toString()}\nFollowing',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserFollowersScreen(thisUser: user),
                                ),
                              );
                            },
                            child: Text(
                              '${(user?['followerCount'] ?? 0).toString()}\nFollowers',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.black,
                      ),
                      width: double.infinity,
                      height: 200,
                      child: ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: Text(
                              user?['userDetail'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
