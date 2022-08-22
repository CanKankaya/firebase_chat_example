import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AddListProvider with ChangeNotifier {
  List<String> addList = [];
  bool isLoading = false;

  bool get isEmpty {
    return addList.isEmpty;
  }

  List<String> get getList {
    return addList;
  }

  clearList() {
    addList = [];
    print('clearList called');
  }

  addToList(String userId) {
    addList.add(userId);
    print(addList);
    notifyListeners();
  }

  removeFromList(String userId) {
    addList.remove(userId);
    print(addList);
    notifyListeners();
  }

  Future<void> addParticipants(String chatId) async {
    try {
      for (var element in addList) {
        FirebaseFirestore.instance.collection('chats/$chatId/participantsData').doc(element).set({
          'userId': element,
        });
      }
      notifyListeners();
      //

    } catch (e) {
      //
    }
  }
}
