import 'package:firebase_chat_example/routetest1.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'main.dart';

class RouteTest2 extends StatefulWidget {
  const RouteTest2({Key? key}) : super(key: key);

  @override
  State<RouteTest2> createState() => _RouteTest2State();
}

class _RouteTest2State extends State<RouteTest2> with RouteAware {
  @override
  void didPush() {
    print('/////////////////\nTest2: Called didPush');
    super.didPush();
  }

  @override
  void didPop() {
    print('/////////////////\nTest2: Called didPop');
    super.didPop();
  }

  @override
  void didPopNext() {
    print('/////////////////\nTest2: Called didPopNext');
    super.didPopNext();
  }

  @override
  void didPushNext() {
    print('/////////////////\nTest2: Called didPushNext');
    super.didPushNext();
  }

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        automaticallyImplyLeading: false,
        title: const Text('Flutter RouteAware Test Page 2'),
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
                      builder: (context) => const RouteTest1(),
                    ),
                  );
                },
                child: const Text("RouteTest2"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
