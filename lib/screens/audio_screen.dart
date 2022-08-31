import 'package:flutter/material.dart';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import 'package:firebase_chat_example/services/audio_manager.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';

//TODO: Try audio stuff here
class AudioScreen extends StatefulWidget {
  const AudioScreen({Key? key}) : super(key: key);

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

//TODO: Try multiple AudioPlayers with different sources

class _AudioScreenState extends State<AudioScreen> {
  late AudioManager _audioManager;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
  }

  @override
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
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
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 1,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.amber,
                  thickness: 1,
                ),
                itemBuilder: (context, index) => Material(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    splashColor: Colors.amber,
                    onTap: () {},
                    child: Theme(
                      data: ThemeData.dark(),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            ValueListenableBuilder<ProgressBarState>(
                              valueListenable: _audioManager.progressNotifier,
                              builder: (_, value, __) {
                                return ProgressBar(
                                  progress: value.current,
                                  buffered: value.buffered,
                                  total: value.total,
                                  onSeek: _audioManager.seek,
                                  progressBarColor: Colors.amber,
                                  thumbColor: Colors.amber,
                                  baseBarColor: Colors.grey[800],
                                  bufferedBarColor: Colors.grey,
                                );
                              },
                            ),
                            ValueListenableBuilder<ButtonState>(
                              valueListenable: _audioManager.buttonNotifier,
                              builder: (_, value, __) {
                                switch (value) {
                                  case ButtonState.loading:
                                    return Container(
                                      margin: const EdgeInsets.all(8.0),
                                      width: 32.0,
                                      height: 32.0,
                                      child: const CircularProgressIndicator(),
                                    );
                                  case ButtonState.paused:
                                    return IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      iconSize: 32.0,
                                      onPressed: _audioManager.play,
                                    );
                                  case ButtonState.playing:
                                    return IconButton(
                                      icon: const Icon(Icons.pause),
                                      iconSize: 32.0,
                                      onPressed: _audioManager.pause,
                                    );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                const Text('DEBUG BUTTON:'),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<ButtonState>(
                    valueListenable: _audioManager.buttonNotifier,
                    builder: (_, value, __) {
                      return ElevatedButton(
                        onPressed: value == ButtonState.loading
                            ? null
                            : () {
                                //TODO: Reset player here
                                _audioManager.pause();
                                _audioManager.seek(Duration.zero);
                              },
                        child: const Text('Reset audio test'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8)
              ],
            ),
            Row(
              children: [
                const Text('DEBUG BUTTON:'),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<ButtonState>(
                    valueListenable: _audioManager.buttonNotifier,
                    builder: (_, value, __) {
                      return ElevatedButton(
                        onPressed: value == ButtonState.loading
                            ? null
                            : () {
                                //TODO: Change url here
                                _audioManager.changeUrl(
                                    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3');
                              },
                        child: const Text('Change audio test'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8)
              ],
            )
          ],
        ),
      ),
    );
  }
}
