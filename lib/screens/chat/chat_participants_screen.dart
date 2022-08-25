import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/widgets/simpler_error_message.dart';

import 'package:firebase_chat_example/screens/other_user/other_userdata_screen.dart';
import 'package:firebase_chat_example/screens/chat/add_participant_screen.dart';
import 'package:firebase_chat_example/screens/public_chats_list_screen.dart';

class ChatParticipantsScreen extends StatelessWidget {
  final String creatorId;
  final String chatId;

  const ChatParticipantsScreen({
    Key? key,
    required this.creatorId,
    required this.chatId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserAdmin = creatorId == currentUser?.uid;

    void _handleClick(int item, String whichUserId) {
      switch (item) {
        case 0:
          final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Remove User'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: const [
                      Text('Are you sure you want to remove this user from the chat?'),
                    ],
                  ),
                ),
                actions: [
                  ValueListenableBuilder(
                    valueListenable: isLoading,
                    builder: (context, bool value, __) {
                      return TextButton(
                        onPressed: () async {
                          if (whichUserId == '') {
                            Navigator.of(context).pop();
                            SchedulerBinding.instance.addPostFrameCallback(
                              (_) {
                                simplerErrorMessage(
                                  context,
                                  'Couldnt find user',
                                  '',
                                  null,
                                  false,
                                );
                              },
                            );
                            return;
                          } else {
                            isLoading.value = true;
                            await FirebaseFirestore.instance
                                .collection('chats/$chatId/participantsData')
                                .doc(whichUserId)
                                .delete()
                                .then(
                              (_) {
                                isLoading.value = false;
                                Navigator.of(context).pop();
                                SchedulerBinding.instance.addPostFrameCallback(
                                  (_) {
                                    simplerErrorMessage(
                                      context,
                                      'Removed User',
                                      '',
                                      null,
                                      false,
                                    );
                                  },
                                );
                              },
                            );
                          }
                        },
                        child: value
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Yes',
                                style: TextStyle(fontSize: 20),
                              ),
                      );
                    },
                  ),
                ],
              );
            },
          );
          break;
        case 1:
          break;
      }
    }

    _deleteCurrentChat(String chatId) async {
      final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Remove Chat'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const [
                  Text('Are you sure you want to delete this chat?'),
                ],
              ),
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: isLoading,
                builder: (context, bool value, __) {
                  return TextButton(
                    onPressed: () async {
                      if (chatId == '') {
                        Navigator.of(context).pop();
                        SchedulerBinding.instance.addPostFrameCallback(
                          (_) {
                            simplerErrorMessage(
                              context,
                              'Couldnt find the chat',
                              '',
                              null,
                              false,
                            );
                          },
                        );
                        return;
                      } else {
                        isLoading.value = true;
                        await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();

                        SchedulerBinding.instance.addPostFrameCallback(
                          (_) {
                            isLoading.value = false;
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) => const PublicChatsListScreen(),
                                ),
                                (route) => false);
                            simplerErrorMessage(
                              context,
                              'Chat Deleted',
                              '',
                              null,
                              false,
                            );
                          },
                        );
                      }
                    },
                    child: value
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Yes',
                            style: TextStyle(fontSize: 20),
                          ),
                  );
                },
              ),
            ],
          );
        },
      );
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('usersData').snapshots(),
      builder: (_, AsyncSnapshot<QuerySnapshot> usersSnapshot) {
        return StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('chats/$chatId/participantsData').snapshots(),
          builder: (_, AsyncSnapshot<QuerySnapshot> participantsSnapshot) {
            if (usersSnapshot.hasData && participantsSnapshot.hasData) {
              final participantsData = participantsSnapshot.data?.docs;
              final usersData = usersSnapshot.data?.docs;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Scaffold(
                  appBar: AppBar(
                    actions: [
                      if (isCurrentUserAdmin)
                        IconButton(
                          onPressed: () => _deleteCurrentChat(chatId),
                          icon: const Icon(Icons.delete_forever),
                        ),
                    ],
                  ),
                  body: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: participantsData?.length,
                    itemBuilder: (context, index) {
                      final whichUser = usersData?.firstWhere((element) {
                        return element['userId'] == participantsData?[index]['userId'];
                      });
                      final isUserAdmin = whichUser?['userId'] == creatorId;
                      final isMe = currentUser?.uid == whichUser?['userId'];

                      return InkWell(
                        onTap: () {
                          if (!isMe) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherUserDataScreen(
                                  user: whichUser,
                                ),
                              ),
                            );
                          }
                        },
                        splashColor: Colors.amber,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 2,
                                    color: Colors.amber,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: CircleAvatar(
                                  radius: 23,
                                  backgroundImage: NetworkImage(
                                    whichUser?['userImageUrl'] ?? '',
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                whichUser?['username'] ?? '',
                              ),
                              if (isUserAdmin)
                                const Text(
                                  '(Admin)',
                                  style: TextStyle(
                                    color: Colors.amber,
                                  ),
                                ),
                              if (whichUser?['userId'] == currentUser?.uid)
                                const Text(
                                  '(You)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              const Spacer(),
                              if (isCurrentUserAdmin && !isMe)
                                PopupMenuButton<int>(
                                  onSelected: (item) =>
                                      _handleClick(item, whichUser?['userId'].toString() ?? ''),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<int>(
                                      value: 0,
                                      child: Text('Remove User'),
                                    ),
                                    const PopupMenuItem<int>(
                                      value: 1,
                                      child: Text('Does nothing yet'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  floatingActionButton: isCurrentUserAdmin
                      ? FloatingActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddParticipantScreen(
                                    chatId: chatId, participantsData: participantsData),
                              ),
                            );
                          },
                          tooltip: 'Add User',
                          child: const Icon(Icons.add),
                        )
                      : null,
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      },
    );
  }
}
