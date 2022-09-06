import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:firebase_chat_example/services/map_service.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/custom_loading.dart';

import 'package:firebase_chat_example/screens/mapstuff/map_screen.dart';

class NoServiceScreen extends StatelessWidget {
  NoServiceScreen({Key? key}) : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPopHandler,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(),
        drawer: const AppDrawer(),
        body: Center(
          child: Column(
            children: [
              const Spacer(),
              const Text(
                'Location Service is Disabled',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Draggable(
                feedback: SizedBox(
                  height: 150,
                  width: 150,
                  child: CustomLoader(),
                ),
                childWhenDragging: SizedBox(
                  height: 150,
                  width: 150,
                ),
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: CustomLoader(),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _buttonHandler(context),
                child: const Text(
                  ('Enable location'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _buttonHandler(BuildContext context) async {
    var boolValue = await mapService.tryGetLocationService();
    if (boolValue) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(),
            ),
          );
        },
      );
    } else {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oh I got denied again. Well, Im used to it :('),
            ),
          );
        },
      );
    }
  }

  Future<bool> onWillPopHandler() {
    if (_scaffoldKey.currentState != null) {
      if (_scaffoldKey.currentState!.isDrawerOpen) {
        _scaffoldKey.currentState!.closeDrawer();
        return Future.value(false);
      } else {
        _scaffoldKey.currentState!.openDrawer();
        return Future.value(false);
      }
    } else {
      return Future.value(false);
    }
  }
}
