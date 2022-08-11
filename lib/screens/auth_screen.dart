import 'package:flutter/material.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/chat_screen.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth-screen';
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  bool _isLogin = true;

  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? _userEmail = '';
  String? _username = '';
  String? _userPassword = '';
  final _userPasswordController = TextEditingController();
  XFile? _pickedImage;

  Future<void> _trySubmit() async {
    if (!_isLogin && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick an Image Please'),
        ),
      );
      return;
    }
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        setState(() {
          _isLoading = true;
        });
        if (_isLogin) {
          await _auth
              .signInWithEmailAndPassword(
                  email: _userEmail.toString().trim(),
                  password: _userPassword.toString().trim())
              .then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );
          }).catchError((error) {
            throw error;
          });
        } else {
          var authResult = await _auth
              .createUserWithEmailAndPassword(
                  email: _userEmail.toString().trim(),
                  password: _userPassword.toString().trim())
              .catchError((error) {
            throw error;
          });

          final ref = FirebaseStorage.instance
              .ref()
              .child('user_image')
              .child('${authResult.user!.uid}.jpg');
          await ref.putFile(File(_pickedImage!.path));
          final url = await ref.getDownloadURL();

          await authResult.user?.updatePhotoURL(url);
          await authResult.user?.updateDisplayName(_username);
          await FirebaseFirestore.instance
              .collection('chats/dJa1VvWu8w3ECOCV6tUb/participantsData')
              .add({
            'userId': authResult.user?.uid,
            'username': _username,
            'userImageUrl': url,
          }).then((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );
          });
        }
        setState(() {
          _isLoading = false;
        });
      } on FirebaseAuthException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Unknown Error'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future _selectImage() async {
    var image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );
    setState(() {
      _pickedImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.amber,
        ),
        child: Scaffold(
          body: Center(
            child: AnimatedContainer(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 600),
              height: _isLogin ? 320 : 500,
              margin: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            CircleAvatar(
                              backgroundColor: Colors.grey,
                              radius: 40,
                              backgroundImage: _pickedImage != null
                                  ? FileImage(File(_pickedImage!.path))
                                  : null,
                            ),
                          if (!_isLogin)
                            TextButton.icon(
                              onPressed: _selectImage,
                              icon: const Icon(Icons.camera),
                              label: const Text('Add Image'),
                            ),
                          TextFormField(
                            key: const ValueKey('email'),
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            maxLength: 50,
                            onSaved: (newValue) {
                              _userEmail = newValue;
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
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email address'),
                          ),
                          if (!_isLogin)
                            TextFormField(
                              key: const ValueKey('username'),
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              onSaved: (newValue) {
                                _username = newValue;
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
                            key: const ValueKey('password'),
                            controller: _userPasswordController,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            maxLength: 30,
                            obscureText: true,
                            onSaved: (newValue) {
                              _userPassword = newValue;
                            },
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length < 8) {
                                return 'Password must be longer than 8 characters';
                              } else {
                                return null;
                              }
                            },
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                          ),
                          if (!_isLogin)
                            TextFormField(
                              key: const ValueKey('confirmPassword'),
                              enabled: !_isLogin,
                              onSaved: (newValue) {
                                _userPassword = newValue;
                              },
                              maxLength: 30,
                              obscureText: true,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.length < 8 ||
                                    value != _userPasswordController.text) {
                                  return 'Passwords do not match';
                                } else {
                                  return null;
                                }
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Confirm Password'),
                            ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: () {
                                    _trySubmit();
                                  },
                                  child: _isLogin
                                      ? const Text('Login')
                                      : const Text('Sign Up'),
                                ),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                    });
                                  },
                                  child: _isLogin
                                      ? const Text('Create New Account')
                                      : const Text('I already have an account'),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
