import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../main.dart';

import 'package:firebase_chat_example/route_test_screens/route_test_4.dart';

class RouteTest3 extends StatelessWidget with RouteAware {
  const RouteTest3({Key? key}) : super(key: key);

  @override
  void didPush() {
    log('Test3: Called didPush');
    super.didPush();
  }

  @override
  void didPop() {
    log('Test3: Called didPop');
    super.didPop();
  }

  @override
  void didPopNext() {
    log('Test3: Called didPopNext');
    super.didPopNext();
  }

  @override
  void didPushNext() {
    log('Test3: Called didPushNext');
    super.didPushNext();
  }

  @override
  Widget build(BuildContext context) {
    log('Test 3 build method ran');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        automaticallyImplyLeading: false,
        title: const Text('Flutter RouteAware Test Page 3'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 20),
                  minimumSize: const Size.fromHeight(40),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RouteTest4(),
                    ),
                  );
                },
                child: const Text("RouteTest3"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
