import 'package:flutter/material.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final auth = FirebaseAuth.instance;

  final ValueNotifier<bool> _isUpdatable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<XFile?> _pickedImage = ValueNotifier<XFile?>(null);

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userDetailController = TextEditingController();

  Future _selectImage() async {
    var image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );
    if (image != null) {
      _pickedImage.value = image;

      _isUpdatable.value = true;
    }
  }

  Future _tryUpdate() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState?.save();
      if (_pickedImage.value != null) {
        _isLoading.value = true;

        final ref = FirebaseStorage.instance
            .ref()
            .child('user_image')
            .child('${auth.currentUser!.uid}.jpg');
        await ref.delete();
        await ref.putFile(File(_pickedImage.value!.path));
        final url = await ref.getDownloadURL();
        await auth.currentUser?.updatePhotoURL(url);
        await auth.currentUser?.updateDisplayName(_usernameController.text);

        final userCollection = FirebaseFirestore.instance.collection('usersData');
        QuerySnapshot userSnapshot = await userCollection.get();
        final whichParticipant = userSnapshot.docs.firstWhere((element) {
          return element['userId'] == auth.currentUser?.uid;
        });

        await userCollection.doc(whichParticipant.id).update({
          'username': _usernameController.text,
          'userImageUrl': url,
          'userDetail': _userDetailController.text,
        }).then((_) {
          _isLoading.value = false;
        });
      } else {
        _isLoading.value = true;

        await auth.currentUser?.updateDisplayName(_usernameController.text);
        final userCollection = FirebaseFirestore.instance.collection('usersData');
        QuerySnapshot userSnapshot = await userCollection.get();
        final whichParticipant = userSnapshot.docs.firstWhere((element) {
          return element['userId'] == auth.currentUser?.uid;
        });

        await userCollection.doc(whichParticipant.id).update({
          'username': _usernameController.text,
          'userDetail': _userDetailController.text,
        }).then((value) {
          _isLoading.value = false;
        });
      }
    }
  }

  Future _getAndSetUserData() async {
    _usernameController.text = auth.currentUser?.displayName ?? '';
    _emailController.text = auth.currentUser?.email ?? '';
    final userCollection = FirebaseFirestore.instance.collection('usersData');
    QuerySnapshot userSnapshot = await userCollection.get();
    final whichParticipant = userSnapshot.docs.firstWhere((element) {
      return element['userId'] == auth.currentUser?.uid;
    });
    _userDetailController.text = whichParticipant['userDetail'];
  }

  @override
  Widget build(BuildContext context) {
    _getAndSetUserData();
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.amber,
          ),
          child: Scaffold(
            appBar: AppBar(),
            drawer: const AppDrawer(),
            body: Center(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: ValueListenableBuilder(
                              valueListenable: _pickedImage,
                              builder: (_, XFile? value, __) {
                                return Stack(
                                  children: [
                                    value == null
                                        ? CircleAvatar(
                                            radius: 60,
                                            backgroundImage:
                                                NetworkImage(auth.currentUser?.photoURL ?? ''),
                                          )
                                        : CircleAvatar(
                                            radius: 60,
                                            backgroundImage: FileImage(File(value.path)),
                                          ),
                                    Positioned(
                                      top: 75,
                                      left: 75,
                                      child: IconButton(
                                        iconSize: 40,
                                        onPressed: _selectImage,
                                        icon: const Icon(
                                          Icons.camera,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                key: const ValueKey('username'),
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                controller: _usernameController,
                                maxLength: 30,
                                decoration: const InputDecoration(labelText: 'Username'),
                                onSaved: (newValue) {
                                  _usernameController.text = newValue ?? '';
                                },
                                onChanged: (_) {
                                  _isUpdatable.value = true;
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Username cant be empty';
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                              TextFormField(
                                key: const ValueKey('userDetail'),
                                autocorrect: true,
                                textCapitalization: TextCapitalization.sentences,
                                controller: _userDetailController,
                                maxLength: 200,
                                decoration: const InputDecoration(labelText: 'User Detail'),
                                maxLines: 10,
                                minLines: 1,
                                onSaved: (newValue) {
                                  _userDetailController.text = newValue ?? '';
                                },
                                onChanged: (_) {
                                  _isUpdatable.value = true;
                                },
                                validator: (value) {
                                  return null;
                                },
                              ),
                              TextFormField(
                                key: const ValueKey('email'),
                                style: const TextStyle(color: Colors.grey),
                                enabled: false,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                // maxLength: 50,
                                onSaved: (newValue) {
                                  _emailController.text = newValue ?? '';
                                },
                                decoration: const InputDecoration(labelText: 'Email'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ValueListenableBuilder(
                      valueListenable: _isLoading,
                      builder: (_, bool loadingValue, __) {
                        return ValueListenableBuilder(
                          valueListenable: _isUpdatable,
                          builder: (_, bool updateValue, __) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.amber,
                              ),
                              onPressed: updateValue
                                  ? () {
                                      _tryUpdate();
                                      _isUpdatable.value = false;
                                    }
                                  : null,
                              child: loadingValue
                                  ? const CircularProgressIndicator()
                                  : Text(
                                      'Update',
                                      style: TextStyle(
                                        color: updateValue ? Colors.black : Colors.grey,
                                      ),
                                    ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
