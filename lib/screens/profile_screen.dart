import 'package:flutter/material.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUpdatable = false;
  bool _isLoading = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userDetailController = TextEditingController();

  XFile? _pickedImage;
  final auth = FirebaseAuth.instance;

  Future _selectImage() async {
    var image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _isUpdatable = true;
      });
    }
  }

  Future _tryUpdate() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState?.save();
      if (_pickedImage != null) {
        setState(() {
          _isLoading = true;
        });
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_image')
            .child('${auth.currentUser!.uid}.jpg');
        await ref.delete();
        await ref.putFile(File(_pickedImage!.path));
        final url = await ref.getDownloadURL();
        await auth.currentUser?.updatePhotoURL(url);
        await auth.currentUser?.updateDisplayName(_usernameController.text);

        final userCollection = FirebaseFirestore.instance
            .collection('chats/dJa1VvWu8w3ECOCV6tUb/participantsData');
        QuerySnapshot userSnapshot = await userCollection.get();
        final whichParticipant = userSnapshot.docs.firstWhere((element) {
          return element['userId'] == auth.currentUser?.uid;
        });

        await userCollection.doc(whichParticipant.id).update({
          'username': _usernameController.text,
          'userImageUrl': url,
          'userDetail': _userDetailController.text,
        }).then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        setState(() {
          _isLoading = true;
        });
        await auth.currentUser?.updateDisplayName(_usernameController.text);
        final userCollection = FirebaseFirestore.instance
            .collection('chats/dJa1VvWu8w3ECOCV6tUb/participantsData');
        QuerySnapshot userSnapshot = await userCollection.get();
        final whichParticipant = userSnapshot.docs.firstWhere((element) {
          return element['userId'] == auth.currentUser?.uid;
        });

        await userCollection.doc(whichParticipant.id).update({
          'username': _usernameController.text,
          'userDetail': _userDetailController.text,
        }).then((value) {
          setState(() {
            _isLoading = false;
          });
        });
      }
    }
  }

  Future _getAndSetUserData() async {
    _usernameController.text = auth.currentUser?.displayName ?? '';
    _emailController.text = auth.currentUser?.email ?? '';
    final userCollection = FirebaseFirestore.instance
        .collection('chats/dJa1VvWu8w3ECOCV6tUb/participantsData');
    QuerySnapshot userSnapshot = await userCollection.get();
    final whichParticipant = userSnapshot.docs.firstWhere((element) {
      return element['userId'] == auth.currentUser?.uid;
    });
    _userDetailController.text = whichParticipant['userDetail'];
  }

  @override
  void initState() {
    _getAndSetUserData().then((_) {
      _isLoading = false;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                        child: Stack(
                          children: [
                            _pickedImage == null
                                ? CircleAvatar(
                                    radius: 60,
                                    backgroundImage: NetworkImage(
                                        auth.currentUser?.photoURL ?? ''),
                                  )
                                : CircleAvatar(
                                    radius: 60,
                                    backgroundImage:
                                        FileImage(File(_pickedImage!.path)),
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
                        ),
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
                              decoration:
                                  const InputDecoration(labelText: 'Username'),
                              onSaved: (newValue) {
                                _usernameController.text = newValue ?? '';
                              },
                              onChanged: (_) {
                                setState(() {
                                  _isUpdatable = true;
                                });
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
                              decoration: const InputDecoration(
                                  labelText: 'User Detail'),
                              maxLines: 10,
                              minLines: 1,
                              onSaved: (newValue) {
                                _userDetailController.text = newValue ?? '';
                              },
                              onChanged: (_) {
                                setState(() {
                                  _isUpdatable = true;
                                });
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
                              onChanged: (_) {
                                setState(() {
                                  _isUpdatable = true;
                                });
                              },
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@')) {
                                  return 'Enter a valid email';
                                } else {
                                  return null;
                                }
                              },
                              decoration:
                                  const InputDecoration(labelText: 'Email'),
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.amber,
                    ),
                    onPressed: _isUpdatable
                        ? () {
                            _tryUpdate();
                            setState(() {
                              _isUpdatable = false;
                            });
                          }
                        : null,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'Update',
                            style: TextStyle(
                              color: _isUpdatable ? Colors.black : Colors.grey,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
