import 'package:firebase_chat_example/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  String? _userEmail = '';
  String? _username = '';
  String? _userPassword = '';
  final _userPasswordController = TextEditingController();

  Future<void> _trySubmit() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print(_userEmail);
      print(_username);
      print(_userPassword);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ChatScreen(),
        ),
      );
    } else {
      return;
    }
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
                          onSaved: (newValue) {
                            _userPassword = newValue;
                          },
                          maxLength: 30,
                          obscureText: true,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 8 ||
                                value == _userPasswordController.text) {
                              return 'error';
                            } else {
                              return null;
                            }
                          },
                          decoration: const InputDecoration(
                              labelText: 'Confirm Password'),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          _trySubmit();
                        },
                        child: isLogin
                            ? const Text('Login')
                            : const Text('Sign Up'),
                      ),
                      TextButton(
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
