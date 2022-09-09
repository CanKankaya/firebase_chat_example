import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

import 'package:firebase_chat_example/services/audio_manager.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/custom_icon_button.dart';

import 'package:firebase_chat_example/screens/mapstuff/no_internet_screen.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({Key? key}) : super(key: key);

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  late AudioManager _audioManager;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  var urls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
  ];
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _audioManager.checkInternet(),
      builder: (context, futureVal) {
        if (futureVal.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!(futureVal.data ?? false)) {
          return NoInternetScreen();
        }
        return WillPopScope(
          onWillPop: onWillPopHandler,
          child: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(),
            drawer: const AppDrawer(),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        urls.length,
                        (index) => CustomPlayer(
                          audioManager: _audioManager,
                          index: index,
                          url: urls[index],
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
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AudioScreen(),
                                      ),
                                    );
                                  },
                            child: const Text('Reset audio test'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8)
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

class CustomPlayer extends StatelessWidget {
  const CustomPlayer({
    Key? key,
    required this.index,
    required this.audioManager,
    required this.url,
  }) : super(key: key);

  final AudioManager audioManager;
  final int index;
  final String url;

  @override
  Widget build(BuildContext context) {
    log('PlayerWidget build method ran');
    var lastPosition = Duration.zero;
    var savedPosition = Duration.zero;

    //TODO: add functions to;

    //currentplayer repeat button
    //other players restart button while paused
    //other players restart button while playing
    //other players repeat button while paused
    //other players repeat button while playing

    //TODO: fix button visual bug when player stops automatically

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          splashColor: Colors.amber,
          onTap: () {},
          child: Theme(
            data: ThemeData.dark(),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Duration>(
                future: audioManager.getDuration(url),
                builder: (context, futureValue) {
                  return Column(
                    children: [
                      ValueListenableBuilder<ProgressBarState>(
                        valueListenable: audioManager.progressNotifier,
                        builder: (_, value, __) {
                          var isThisActive = audioManager.lastActiveIndex.value == index;
                          if (isThisActive) {
                            lastPosition = value.current;

                            //TODO: this is a temporary "on audio finished" function
                            //Find a proper way to trigger this
                            if (value.current >= value.total - const Duration(milliseconds: 300)) {
                              //
                              log('check if audio finished');
                              audioManager.pause();

                              audioManager.seek(
                                position: Duration.zero,
                              );
                            }
                          }

                          return ProgressBar(
                            progress: isThisActive ? value.current : lastPosition,
                            buffered: isThisActive ? value.buffered : Duration.zero,
                            total: futureValue.data ?? Duration.zero,
                            onSeek: isThisActive
                                ? (position) {
                                    audioManager.seek(
                                      position: position,
                                    );
                                    audioManager.isPlaying
                                        ? audioManager.initIcon.value = false
                                        : audioManager.initIcon.value = true;
                                  }
                                : (position) async {
                                    log(position.toString());
                                    await audioManager.changeUrl(url, index, position);
                                    audioManager.seek(
                                      position: position,
                                    );
                                    audioManager.play(index);
                                  },
                            progressBarColor: isThisActive ? Colors.amber : Colors.teal,
                            thumbColor: isThisActive ? Colors.amber : Colors.teal,
                            baseBarColor: Colors.grey[800],
                            bufferedBarColor: Colors.grey,
                          );
                        },
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: audioManager.lastActiveIndex,
                        builder: (_, indexValue, __) {
                          return ValueListenableBuilder<ButtonState>(
                            valueListenable: audioManager.buttonNotifier,
                            builder: (_, buttonValue, __) {
                              if (audioManager.lastActiveIndex.value == index) {
                                return buttonValue == ButtonState.loading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: const [
                                          IconButton(
                                            onPressed: null,
                                            icon: Icon(
                                              Icons.replay,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                          IconButton(
                                            onPressed: null,
                                            icon: Icon(
                                              Icons.repeat,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: lastPosition == Duration.zero
                                                ? null
                                                : () {
                                                    audioManager.pause();
                                                    audioManager.initIcon.value = true;
                                                    audioManager.seek(
                                                      position: Duration.zero,
                                                    );
                                                  },
                                            icon: const Icon(Icons.replay),
                                          ),
                                          ValueListenableBuilder<bool>(
                                              valueListenable: audioManager.initIcon,
                                              builder: (context, initValue, __) {
                                                return CustomIconButton(
                                                  icon: initValue
                                                      ? AnimatedIcons.play_pause
                                                      : AnimatedIcons.pause_play,
                                                  onPressed: audioManager.isPlaying
                                                      ? () {
                                                          audioManager.pause();
                                                        }
                                                      : () async {
                                                          audioManager.play(index);
                                                        },
                                                );
                                              }),
                                          //TODO: set LoopMode of the current player
                                          IconButton(
                                            onPressed: () {},
                                            icon: const Icon(Icons.repeat),
                                          ),
                                        ],
                                      );
                              } else {
                                switch (buttonValue) {
                                  case ButtonState.loading:
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        IconButton(
                                          onPressed: null,
                                          icon: Icon(
                                            Icons.replay,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: null,
                                          icon: Icon(Icons.play_arrow),
                                          iconSize: 24,
                                        ),
                                        IconButton(
                                          onPressed: null,
                                          icon: Icon(Icons.repeat),
                                        ),
                                      ],
                                    );
                                  case ButtonState.paused:
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const IconButton(
                                          onPressed: null,
                                          icon: Icon(
                                            Icons.replay,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            savedPosition = lastPosition;
                                            await audioManager.changeUrl(url, index, savedPosition);
                                            audioManager.seek(
                                              position: savedPosition,
                                            );
                                            audioManager.play(index);
                                          },
                                          icon: const Icon(Icons.play_arrow),
                                          iconSize: 24,
                                        ),
                                        const IconButton(
                                          onPressed: null,
                                          icon: Icon(Icons.repeat),
                                        ),
                                      ],
                                    );
                                  case ButtonState.playing:
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const IconButton(
                                          onPressed: null,
                                          icon: Icon(
                                            Icons.replay,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            savedPosition = lastPosition;
                                            await audioManager.changeUrl(url, index, savedPosition);
                                            audioManager.seek(
                                              position: savedPosition,
                                            );
                                            audioManager.play(index);
                                          },
                                          icon: const Icon(Icons.play_arrow),
                                          iconSize: 24,
                                        ),
                                        const IconButton(
                                          onPressed: null,
                                          icon: Icon(Icons.repeat),
                                        ),
                                      ],
                                    );
                                }
                              }
                            },
                          );
                        },
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
  }
}
