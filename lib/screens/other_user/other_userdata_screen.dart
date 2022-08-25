import 'package:firebase_chat_example/screens/chat/private_chat_screen.dart';
import 'package:firebase_chat_example/services/message_service.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/services/following_service.dart';

import 'package:firebase_chat_example/widgets/simpler_error_message.dart';

import 'package:firebase_chat_example/screens/other_user/otheruser_followers_screen.dart';
import 'package:firebase_chat_example/screens/other_user/otheruser_following_screen.dart';

class OtherUserDataScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Object?>? user;

  const OtherUserDataScreen({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ValueNotifier<bool> fIsLoading = ValueNotifier<bool>(false);
    final ValueNotifier<bool> mIsLoading = ValueNotifier<bool>(false);

    //TODO: follower count doesnt update here when you follow/unfollow

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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('usersData').snapshots(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> usersSnapshot) {
                        if (usersSnapshot.hasData) {
                          final usersData = usersSnapshot.data?.docs;
                          final currentUserData =
                              usersData?.firstWhere((element) => element.id == currentUser?.uid);
                          final List<dynamic> followingList = currentUserData?['following'];
                          final foundUser = followingList
                              .firstWhereOrNull((element) => element == user?['userId']);
                          final bool amIFollowing = foundUser == null ? false : true;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: fIsLoading,
                                builder: (_, bool loading, __) {
                                  return SizedBox(
                                    width: 90,
                                    child: ElevatedButton(
                                      onPressed: loading
                                          ? null
                                          : () async {
                                              fIsLoading.value = true;
                                              amIFollowing
                                                  ? await followService
                                                      .unfollow(user?['userId'])
                                                      .then((_) {
                                                      fIsLoading.value = false;
                                                      ScaffoldMessenger.of(context)
                                                          .clearSnackBars();
                                                      simplerErrorMessage(
                                                        context,
                                                        'UnFollowed \'${user?['username'] ?? ''}\' :(',
                                                        '',
                                                        null,
                                                        false,
                                                      );
                                                    })
                                                  : await followService
                                                      .follow(user?['userId'])
                                                      .then(
                                                      (_) {
                                                        fIsLoading.value = false;
                                                        ScaffoldMessenger.of(context)
                                                            .clearSnackBars();
                                                        simplerErrorMessage(
                                                          context,
                                                          'Following \'${user?['username'] ?? ''}\'!',
                                                          '',
                                                          null,
                                                          false,
                                                        );
                                                      },
                                                    );
                                            },
                                      child: loading
                                          ? const CircularProgressIndicator()
                                          : Text(amIFollowing ? 'UnFollow' : 'Follow'),
                                    ),
                                  );
                                },
                              ),
                              ValueListenableBuilder(
                                valueListenable: mIsLoading,
                                builder: (context, bool loading, __) {
                                  return SizedBox(
                                    width: 130,
                                    child: ElevatedButton(
                                      onPressed: loading
                                          ? null
                                          : () async {
                                              mIsLoading.value = true;
                                              messageService
                                                  .createPrivateChat(user?['userId'])
                                                  .then(
                                                (privChatId) {
                                                  mIsLoading.value = false;
                                                  Navigator.pushAndRemoveUntil(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (BuildContext context) =>
                                                            PrivateChatScreen(
                                                                chatId: privChatId,
                                                                otherUser: user),
                                                      ),
                                                      (route) => false);
                                                },
                                              );
                                            },
                                      child: loading
                                          ? const CircularProgressIndicator()
                                          : const Text('Send Message'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 90,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Follow'),
                                ),
                              ),
                              SizedBox(
                                width: 130,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Send Message'),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
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
