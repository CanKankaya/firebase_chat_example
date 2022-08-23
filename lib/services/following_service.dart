import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final followService = FollowingService();

class FollowingService {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final usersData = FirebaseFirestore.instance.collection('usersData');

  Future follow(String id) async {
    await usersData.doc(currentUserId).update({
      'following': FieldValue.arrayUnion([id]),
      'followingCount': FieldValue.increment(1),
    });

    await usersData.doc(id).update({
      //
      'followers': FieldValue.arrayUnion([currentUserId]),
      'followerCount': FieldValue.increment(1),
    });

    //
  }

  Future unfollow(String id) async {
    await usersData.doc(currentUserId).update({
      'following': FieldValue.arrayRemove([id]),
      'followingCount': FieldValue.increment(-1),
    });
    await usersData.doc(id).update({
      'followers': FieldValue.arrayRemove([currentUserId]),
      'followerCount': FieldValue.increment(-1),
    });
    //
  }
}
