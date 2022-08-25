import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final messageService = MessageService();

class MessageService {
  final usersData = FirebaseFirestore.instance.collection('usersData');

  Future<String> createPrivateChat(String id) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    try {
      //TODO: also check if a message already exists

      final String generatedId = '$currentUserId$id';
      final String potentialId = '$id$currentUserId';

      DocumentSnapshot ds =
          await FirebaseFirestore.instance.collection('privateChats').doc(generatedId).get();
      if (ds.exists) {
        return ds.id;
      }
      ds = await FirebaseFirestore.instance.collection('privateChats').doc(potentialId).get();
      if (ds.exists) {
        return ds.id;
      }

      await FirebaseFirestore.instance.collection('privateChats').doc(generatedId).set({
        'chatCreatorId': currentUserId,
        'chatName': 'Private chat',
        'createdAt': DateTime.now(),
      });
      await FirebaseFirestore.instance
          .collection('privateChats/$generatedId/participantsData')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
      });
      FirebaseFirestore.instance
          .collection('privateChats/$generatedId/participantsData')
          .doc(id)
          .set({
        'userId': id,
      });
      return generatedId;
    } catch (error) {
      rethrow;
    }
  }
}
