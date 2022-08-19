import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_chat_example/screens/other_userdata_screen.dart';

class ChatParticipantsScreen extends StatelessWidget {
  final List<Map<String, dynamic>>? docData;

  const ChatParticipantsScreen({super.key, required this.docData});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>>? usersData;

    _getUsers() async {
      var snapshot = await FirebaseFirestore.instance.collection('usersData').get();
      usersData = snapshot.docs.map((e) => e.data()).toList();
      return usersData;
    }

    return FutureBuilder(
      future: _getUsers(),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Scaffold(
              appBar: AppBar(),
              body: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: docData?.length,
                itemBuilder: (context, index) {
                  final whichUser = usersData?.firstWhere((element) {
                    return element['userId'] == docData?[index]['userId'];
                  });
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
                          const Spacer(),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.more_vert,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
