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

//TODO: save the last progress location and use it later
  @override
  Widget build(BuildContext context) {
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
                          return ProgressBar(
                            progress: audioManager.lastActiveIndex.value == index
                                ? value.current
                                : Duration.zero,
                            //TODO:
                            buffered: audioManager.lastActiveIndex.value == index
                                ? value.buffered
                                : Duration.zero,
                            total: futureValue.data ?? Duration.zero,
                            onSeek: audioManager.lastActiveIndex.value == index
                                ? (position) {
                                    audioManager.seek(
                                      index: index,
                                      position: position,
                                      urlToChange: url,
                                    );
                                    audioManager.isPlaying
                                        ? audioManager.initIcon.value = false
                                        : audioManager.initIcon.value = true;
                                  }
                                : (position) async {
                                    await audioManager.changeUrl(url, index);
                                    audioManager.play(index);
                                    audioManager.seek(
                                      index: index,
                                      position: position,
                                      urlToChange: url,
                                    );
                                  },
                            progressBarColor: Colors.amber,
                            thumbColor: Colors.amber,
                            baseBarColor: Colors.grey[800],
                            bufferedBarColor: Colors.grey,
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: audioManager.initIcon,
                        builder: (_, initValue, __) {
                          return ValueListenableBuilder<int>(
                            valueListenable: audioManager.lastActiveIndex,
                            builder: (_, indexValue, __) {
                              return ValueListenableBuilder<ButtonState>(
                                valueListenable: audioManager.buttonNotifier,
                                builder: (_, value, __) {
                                  if (audioManager.lastActiveIndex.value == index) {
                                    return value == ButtonState.loading
                                        ? const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: CircularProgressIndicator(),
                                          )
                                        : CustomIconButton(
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
                                  } else {
                                    switch (value) {
                                      case ButtonState.loading:
                                        return IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.play_arrow),
                                          iconSize: 24,
                                        );
                                      case ButtonState.paused:
                                        return IconButton(
                                          onPressed: () async {
                                            await audioManager.changeUrl(url, index);
                                            audioManager.play(index);
                                          },
                                          icon: const Icon(Icons.play_arrow),
                                          iconSize: 24,
                                        );

                                      case ButtonState.playing:
                                        return IconButton(
                                          onPressed: () async {
                                            await audioManager.changeUrl(url, index);
                                            audioManager.play(index);
                                          },
                                          icon: const Icon(Icons.play_arrow),
                                          iconSize: 24,
                                        );
                                    }
                                  }
                                },
                              );
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
