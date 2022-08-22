import 'package:firebase_chat_example/widgets/simpler_error_message.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/screens/other_userdata_screen.dart';
import 'package:flutter/scheduler.dart';

class ChatParticipantsScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot<Object?>>? participantsData;
  final String creatorId;
  final String chatId;

  const ChatParticipantsScreen({
    Key? key,
    this.participantsData,
    required this.creatorId,
    required this.chatId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>>? usersData;
    final currentUser = FirebaseAuth.instance.currentUser;

    _getUsers() async {
      var snapshot = await FirebaseFirestore.instance.collection('usersData').get();
      usersData = snapshot.docs.map((e) => e.data()).toList();
      return usersData;
    }

    void _handleClick(int item, String whichUserId) {
      switch (item) {
        case 0:
          final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('errorTitle'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: const [
                      Text('errorText'),
                      Text('errorText2'),
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
                              SchedulerBinding.instance.addPostFrameCallback((_) {
                                simplerErrorMessage(
                                  context,
                                  'Couldnt find user',
                                  '',
                                  null,
                                  false,
                                );
                              });
                              return;
                            } else {
                              isLoading.value = true;
                              await FirebaseFirestore.instance
                                  .collection('chats/$chatId/participantsData')
                                  .doc(whichUserId)
                                  .delete()
                                  .then((_) {
                                isLoading.value = false;
                                Navigator.of(context).pop();
                                SchedulerBinding.instance.addPostFrameCallback((_) {
                                  simplerErrorMessage(
                                    context,
                                    'Removed User',
                                    '',
                                    null,
                                    false,
                                  );
                                });
                              });
                            }
                          },
                          child: value
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'buttonText',
                                  style: TextStyle(fontSize: 20),
                                ),
                        );
                      }),
                ],
              );
            },
          );
          break;
        case 1:
          break;
      }
    }

    return FutureBuilder(
      future: _getUsers(),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final isCurrentUserAdmin = creatorId == currentUser?.uid;
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Scaffold(
              appBar: AppBar(),
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
                    onTap: () {},
                    splashColor: Colors.amber,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserDataScreen(
                                    whichParticipantData: [
                                      whichUser?['userId'] ?? '',
                                      whichUser?['userImageUrl'] ?? '',
                                      whichUser?['username'] ?? '',
                                      whichUser?['userDetail'] ?? '',
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
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
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  //TODO: show a list of all users here
                },
                tooltip: 'Add User',
                child: const Icon(Icons.add),
              ),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
