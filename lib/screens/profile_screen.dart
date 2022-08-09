import 'dart:io';
import 'package:flutter/material.dart';

// import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUpdatable = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
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
      print('yey form is fine');
      if (_pickedImage != null) {
        print('Update img aswell');
        //Do user update here INCLUDING NEW IMAGE;

        // final ref = FirebaseStorage.instance
        //     .ref()
        //     .child('user_image')
        //     .child('${auth.currentUser!.uid}.jpg');
        // await ref.delete();
        // await ref.putFile(File(_pickedImage!.path));

      } else {
        print('dont update img');
        //Do user update here WITHOUT NEW IMAGE;
      }
    }
  }

  @override
  void initState() {
    _usernameController.text = auth.currentUser?.displayName ?? '';
    _emailController.text = auth.currentUser?.email ?? '';

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          onSaved: (newValue) {
                            _usernameController.text = newValue ?? '';
                          },
                          onChanged: (value) {
                            setState(() {
                              _isUpdatable = true;
                            });
                          },
                          maxLength: 30,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username cant be empty';
                            } else {
                              return null;
                            }
                          },
                          decoration:
                              const InputDecoration(labelText: 'Username'),
                        ),
                        TextFormField(
                          key: const ValueKey('email'),
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          onSaved: (newValue) {
                            _emailController.text = newValue ?? '';
                          },
                          onChanged: (value) {
                            setState(() {
                              _isUpdatable = true;
                            });
                          },
                          maxLength: 50,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return 'Enter a valid email';
                            } else {
                              return null;
                            }
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.amber,
                ),
                onPressed: _isUpdatable
                    ? () {
                        // do an update here, then show loading spinner, then set updatable to false again,
                        _tryUpdate();
                        setState(() {
                          _isUpdatable = false;
                        });
                      }
                    : null,
                child: Text(
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
    );
  }
}
