import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_chat_example/screens/chat_screen.dart';
import 'package:image_picker/image_picker.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  bool isLogin = true;

  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? _userEmail = '';
  String? _username = '';
  String? _userPassword = '';
  final _userPasswordController = TextEditingController();
  XFile? _pickedImage;

  Future<void> _trySubmit() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      UserCredential authResult;
      try {
        setState(() {
          _isLoading = true;
        });
        if (isLogin) {
          await _auth
              .signInWithEmailAndPassword(
                  email: _userEmail.toString().trim(),
                  password: _userPassword.toString().trim())
              .then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );
          });
        } else {
          authResult = await _auth.createUserWithEmailAndPassword(
              email: _userEmail.toString().trim(),
              password: _userPassword.toString().trim());
          await authResult.user?.updateDisplayName(_username).then((value) {
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
      } on PlatformException catch (error) {
        //
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message.toString()),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future _selectImage() async {
    var image = await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      _pickedImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.amber,
      ),
      child: Scaffold(
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isLogin)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _pickedImage != null
                              ? FileImage(_pickedImage as File)
                              : null,
                        ),
                      if (!isLogin)
                        TextButton.icon(
                          onPressed: _selectImage,
                          icon: const Icon(Icons.camera),
                          label: const Text('Add Image'),
                        ),
                      TextFormField(
                        key: const ValueKey('email'),
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
                        decoration:
                            const InputDecoration(labelText: 'Email address'),
                      ),
                      if (!isLogin)
                        TextFormField(
                          key: const ValueKey('username'),
                          onSaved: (newValue) {
                            _username = newValue;
                          },
                          maxLength: 30,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'error';
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
                        onSaved: (newValue) {
                          _userPassword = newValue;
                        },
                        maxLength: 30,
                        obscureText: true,
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
                      if (!isLogin)
                        TextFormField(
                          key: const ValueKey('confirmPassword'),
                          enabled: !isLogin,
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
                              child: isLogin
                                  ? const Text('Login')
                                  : const Text('Sign Up'),
                            ),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: () {
                                setState(() {
                                  isLogin = !isLogin;
                                });
                              },
                              child: isLogin
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
    );
  }
}
