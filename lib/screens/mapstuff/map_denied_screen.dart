import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:firebase_chat_example/services/map_service.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/custom_loading.dart';

import 'package:firebase_chat_example/screens/mapstuff/map_screen.dart';

class MapDeniedScreen extends StatelessWidget {
  MapDeniedScreen({Key? key}) : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onWillPopHandler,
      child: Scaffold(
        appBar: AppBar(),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            const Spacer(),
            const Text(
              'You denied me...\nJust like all the girls I ask out. haha :\') ',
              textAlign: TextAlign.center,
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
                ('Try again...'),
              ),
            )
          ],
        ),
      ),
    );
  }

  _buttonHandler(BuildContext context) async {
    var boolValue = await MapService().tryGetPermission();
    if (boolValue) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MapScreen(),
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
