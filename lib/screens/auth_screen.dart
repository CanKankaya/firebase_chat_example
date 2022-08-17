import 'package:flutter/material.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_chat_example/widgets/exit_popup.dart';

import 'package:firebase_chat_example/screens/splash_screen.dart';
import 'package:firebase_chat_example/screens/chats_list_screen.dart';

class AuthScreen extends StatelessWidget {
  AuthScreen({Key? key}) : super(key: key);

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLogin = ValueNotifier<bool>(true);
  final ValueNotifier<XFile?> _pickedImage = ValueNotifier<XFile?>(null);
  final ValueNotifier<bool> _hidePassword = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _hideConfirmPassword = ValueNotifier<bool>(true);

  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final _userPasswordController = TextEditingController();

  Future _selectImage() async {
    var image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );
    _pickedImage.value = image;
  }

  @override
  Widget build(BuildContext context) {
    String? userEmail = '';
    String? username = '';
    String? userPassword = '';
    Future<void> _trySubmit() async {
      if (!_isLogin.value && _pickedImage.value == null) {
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
          _isLoading.value = true;

          if (_isLogin.value) {
            await _auth
                .signInWithEmailAndPassword(
                    email: userEmail.toString().trim(), password: userPassword.toString().trim())
                .then((_) {
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const ChatScreen(),
              //   ),
              // );
            }).catchError((error) {
              throw error;
            });
          } else {
            var authResult = await _auth
                .createUserWithEmailAndPassword(
                    email: userEmail.toString().trim(), password: userPassword.toString().trim())
                .catchError((error) {
              throw error;
            });

            final ref = FirebaseStorage.instance
                .ref()
                .child('user_image')
                .child('${authResult.user!.uid}.jpg');
            await ref.putFile(File(_pickedImage.value!.path));
            final url = await ref.getDownloadURL();

            await authResult.user?.updatePhotoURL(url);
            await authResult.user?.updateDisplayName(username);
            //TODO: problem: When sign up, user is auto added to participants of the first chat
            await FirebaseFirestore.instance
                .collection('chats/dJa1VvWu8w3ECOCV6tUb/participantsData')
                .add({
              'userId': authResult.user?.uid,
              'username': username,
              'userImageUrl': url,
              'userDetail': '',
            });
            // SchedulerBinding.instance.addPostFrameCallback((_) {
            //   //
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => const ChatScreen(),
            //     ),
            //   );
            // });
          }

          _isLoading.value = false;
        } on FirebaseAuthException catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message ?? 'Unknown Error'),
            ),
          );

          _isLoading.value = false;
        }
      }
    }

    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const SplashScreen();
        } else {
          return snapshot.hasData
              ? const ChatsListScreen()
              : WillPopScope(
                  onWillPop: () => showExitPopup(context),
                  child: Theme(
                    data: ThemeData.dark(),
                    child: Scaffold(
                      body: Center(
                        child: ValueListenableBuilder(
                          valueListenable: _isLogin,
                          builder: (_, bool isLoginValue, __) {
                            return AnimatedContainer(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              curve: Curves.easeIn,
                              duration: isLoginValue
                                  ? const Duration(milliseconds: 250)
                                  : const Duration(milliseconds: 500),
                              height: isLoginValue ? 320 : 500,
                              margin: const EdgeInsets.all(20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Form(
                                      key: _formKey,
                                      child: ValueListenableBuilder(
                                        valueListenable: _isLoading,
                                        builder: (_, bool loadingValue, __) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!isLoginValue)
                                                ValueListenableBuilder(
                                                    valueListenable: _pickedImage,
                                                    builder: (_, XFile? value, __) {
                                                      return CircleAvatar(
                                                        backgroundColor: Colors.grey,
                                                        radius: 40,
                                                        backgroundImage: value != null
                                                            ? FileImage(File(value.path))
                                                            : null,
                                                      );
                                                    }),
                                              if (!isLoginValue)
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
                                                  userEmail = newValue;
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
                                              if (!isLoginValue)
                                                TextFormField(
                                                  key: const ValueKey('username'),
                                                  autocorrect: false,
                                                  textCapitalization: TextCapitalization.none,
                                                  onSaved: (newValue) {
                                                    username = newValue;
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
                                              ValueListenableBuilder(
                                                  valueListenable: _hidePassword,
                                                  builder: (_, bool hidePasswordValue, __) {
                                                    return TextFormField(
                                                      key: const ValueKey('password'),
                                                      controller: _userPasswordController,
                                                      autocorrect: false,
                                                      textCapitalization: TextCapitalization.none,
                                                      maxLength: 30,
                                                      obscureText: hidePasswordValue,
                                                      onSaved: (newValue) {
                                                        userPassword = newValue;
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
                                                      decoration: InputDecoration(
                                                        labelText: 'Password',
                                                        suffixIcon: IconButton(
                                                          onPressed: () {
                                                            _hidePassword.value =
                                                                !_hidePassword.value;
                                                          },
                                                          icon: hidePasswordValue
                                                              ? const Icon(
                                                                  Icons.visibility_off,
                                                                  color: Colors.grey,
                                                                )
                                                              : const Icon(
                                                                  Icons.visibility,
                                                                  color: Colors.blue,
                                                                ),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                              if (!isLoginValue)
                                                ValueListenableBuilder(
                                                    valueListenable: _hideConfirmPassword,
                                                    builder: (context, bool confirmPassValue, __) {
                                                      return TextFormField(
                                                        key: const ValueKey('confirmPassword'),
                                                        enabled: !isLoginValue,
                                                        onSaved: (newValue) {
                                                          userPassword = newValue;
                                                        },
                                                        maxLength: 30,
                                                        obscureText: confirmPassValue,
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty ||
                                                              value.length < 8 ||
                                                              value !=
                                                                  _userPasswordController.text) {
                                                            return 'Passwords do not match';
                                                          } else {
                                                            return null;
                                                          }
                                                        },
                                                        decoration: InputDecoration(
                                                          labelText: 'Confirm Password',
                                                          suffixIcon: IconButton(
                                                            onPressed: () {
                                                              _hideConfirmPassword.value =
                                                                  !_hideConfirmPassword.value;
                                                            },
                                                            icon: confirmPassValue
                                                                ? const Icon(
                                                                    Icons.visibility_off,
                                                                    color: Colors.grey,
                                                                  )
                                                                : const Icon(
                                                                    Icons.visibility,
                                                                    color: Colors.blue,
                                                                  ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                              const SizedBox(height: 12),
                                              loadingValue
                                                  ? const CircularProgressIndicator()
                                                  : ElevatedButton(
                                                      onPressed: () {
                                                        _trySubmit();
                                                      },
                                                      child: isLoginValue
                                                          ? const Text('Login')
                                                          : const Text('Sign Up'),
                                                    ),
                                              loadingValue
                                                  ? const CircularProgressIndicator()
                                                  : TextButton(
                                                      onPressed: () {
                                                        _isLogin.value = !_isLogin.value;
                                                      },
                                                      child: isLoginValue
                                                          ? const Text('Create New Account')
                                                          : const Text('I already have an account'),
                                                    ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
        }
      },
    );
  }
}
