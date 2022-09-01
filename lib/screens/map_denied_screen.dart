import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:firebase_chat_example/services/map_service.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/custom_loading.dart';

import 'package:firebase_chat_example/screens/map_screen.dart';

class MapDeniedScreen extends StatelessWidget {
  const MapDeniedScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

    return WillPopScope(
      onWillPop: () {
        if (scaffoldKey.currentState != null) {
          if (scaffoldKey.currentState!.isDrawerOpen) {
            scaffoldKey.currentState!.closeDrawer();
            return Future.value(false);
          } else {
            scaffoldKey.currentState!.openDrawer();
            return Future.value(false);
          }
        } else {
          return Future.value(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            const Spacer(),
            const Text(
              'Well I just got denied.\nJust like all the girls I ask out. haha :\') ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CustomLoader(),
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
}
