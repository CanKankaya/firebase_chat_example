import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:firebase_chat_example/providers/add_participant_provider.dart';

import 'package:firebase_chat_example/widgets/simpler_error_message.dart';

class AddParticipantScreen extends StatelessWidget {
  const AddParticipantScreen({Key? key, this.participantsData, required this.chatId})
      : super(key: key);
  final String chatId;
  final List<QueryDocumentSnapshot<Object?>>? participantsData;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Provider.of<AddListProvider>(context, listen: false).clearList();
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('usersData').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> usersSnapshot) {
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (usersSnapshot.hasData) {
              final usersData = usersSnapshot.data?.docs;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: usersData?.length ?? 0,
                      itemBuilder: (context, index) {
                        final user = participantsData?.firstWhereOrNull((element) {
                          return element.id == usersData?[index]['userId'];
                        });
                        if (user == null) {
                          return UserItem(
                            user: usersData?[index],
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: Consumer<AddListProvider>(
                      builder: (_, providerValue, __) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.amber,
                          ),
                          onPressed: providerValue.isEmpty
                              ? null
                              : () {
                                  providerValue.addParticipants(chatId).then(
                                    (_) {
                                      providerValue.clearList();
                                      Navigator.of(context).pop();
                                      SchedulerBinding.instance.addPostFrameCallback(
                                        (_) {
                                          simplerErrorMessage(
                                            context,
                                            'Added Users',
                                            '',
                                            null,
                                            false,
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                          child: const Text(
                            'Add Selected Users',
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

class UserItem extends StatelessWidget {
  const UserItem({Key? key, this.user}) : super(key: key);
  final QueryDocumentSnapshot<Object?>? user;

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isChecked = ValueNotifier<bool>(false);
    return ValueListenableBuilder(
      valueListenable: isChecked,
      builder: (_, bool value, __) {
        return CheckboxListTile(
          activeColor: Colors.amber,
          checkColor: Colors.black,
          title: Text(user?['username'] ?? ''),
          subtitle: Text(
            user?['userDetail'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
          secondary: Container(
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
                user?['userImageUrl'] ?? '',
              ),
            ),
          ),
          value: value,
          onChanged: (_) {
            isChecked.value = !isChecked.value;

            if (!value) {
              Provider.of<AddListProvider>(context, listen: false).addToList(user?['userId'] ?? '');
            } else {
              Provider.of<AddListProvider>(context, listen: false)
                  .removeFromList(user?['userId'] ?? '');
            }
          },
        );
      },
    );
  }
}
