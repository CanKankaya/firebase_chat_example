import 'package:firebase_chat_example/routetest3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'main.dart';

class RouteTest4 extends StatefulWidget {
  const RouteTest4({Key? key}) : super(key: key);

  @override
  State<RouteTest4> createState() => _RouteTest4State();
}

class _RouteTest4State extends State<RouteTest4> with RouteAware {
  @override
  void didPush() {
    print('//////////////\nTest1: Called didPush');
    super.didPush();
  }

  @override
  void didPop() {
    print('//////////////\nTest1: Called didPop');
    super.didPop();
  }

  @override
  void didPopNext() {
    print('//////////////\nTest1: Called didPopNext');
    super.didPopNext();
  }

  @override
  void didPushNext() {
    print('//////////////\nTest1: Called didPushNext');
    super.didPushNext();
  }

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
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
        title: const Text('Flutter RouteAware Test Page 4'),
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
                        builder: (context) => const RouteTest3(),
                      ),
                    );
                  },
                  child: const Text("RouteTest4")),
            ],
          ),
        ),
      ),
    );
  }
}
