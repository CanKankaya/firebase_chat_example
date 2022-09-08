import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  var urlDurations = [];
  @override
  Widget build(BuildContext context) {
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
                  ).toList(),
                ),
              ),
              // child: ListView.separated(
              //   padding: const EdgeInsets.all(16),
              //   itemCount: urls.length,
              //   separatorBuilder: (context, index) => const Divider(
              //     color: Colors.amber,
              //     thickness: 1,
              //   ),
              //   itemBuilder: (context, index) => CustomPlayer(
              //     audioManager: _audioManager,
              //     index: index,
              //     url: urls[index],
              //   ),
              // ),
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
                                _audioManager.dispose();
                                _audioManager.init();
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
                                    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3');
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

  void initDurations() async {
    for (var element in urls) {
      var item = _audioManager.getDuration(element);
      urlDurations.add(item);
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
                              progress: audioManager.lastActiveIndex == index
                                  ? value.current
                                  : Duration.zero,
                              buffered: audioManager.lastActiveIndex == index
                                  ? value.buffered
                                  : Duration.zero,
                              total: futureValue.data ?? Duration.zero,
                              onSeek: audioManager.lastActiveIndex == index
                                  ? (position) => audioManager.seek(
                                        index: index,
                                        position: position,
                                        urlToChange: url,
                                      )
                                  : (position) async {
                                      audioManager.isPlaying = true;
                                      await audioManager.changeUrl(url);
                                      audioManager.play(index);
                                      audioManager.seek(
                                        index: index,
                                        position: position,
                                        urlToChange: url,
                                      );
                                      SchedulerBinding.instance.addPostFrameCallback((_) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(audioManager.lastActiveIndex.toString()),
                                          ),
                                        );
                                      });
                                    },
                              progressBarColor: Colors.amber,
                              thumbColor: Colors.amber,
                              baseBarColor: Colors.grey[800],
                              bufferedBarColor: Colors.grey,
                            );
                          },
                        ),
                        ValueListenableBuilder<ButtonState>(
                          valueListenable: audioManager.buttonNotifier,
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
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  iconSize: 32,
                                  onPressed: audioManager.isPlaying &&
                                          audioManager.lastActiveIndex != index
                                      ? () {
                                          ScaffoldMessenger.of(context).clearSnackBars();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Did nothing'),
                                            ),
                                          );
                                        }
                                      : () async {
                                          //TODO:
                                          audioManager.isPlaying = true;
                                          await audioManager.changeUrl(url);
                                          audioManager.play(index);
                                          SchedulerBinding.instance.addPostFrameCallback((_) {
                                            ScaffoldMessenger.of(context).clearSnackBars();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text(audioManager.lastActiveIndex.toString()),
                                              ),
                                            );
                                          });
                                        },
                                );
                              case ButtonState.playing:
                                return audioManager.isPlaying &&
                                        audioManager.lastActiveIndex != index
                                    ? IconButton(
                                        icon: const Icon(Icons.play_arrow_rounded),
                                        iconSize: 32,
                                        onPressed: () async {
                                          audioManager.isPlaying = true;
                                          await audioManager.changeUrl(url);
                                          audioManager.play(index);
                                          SchedulerBinding.instance.addPostFrameCallback((_) {
                                            ScaffoldMessenger.of(context).clearSnackBars();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text(audioManager.lastActiveIndex.toString()),
                                              ),
                                            );
                                          });
                                        })
                                    : IconButton(
                                        icon: const Icon(Icons.pause),
                                        iconSize: 32,
                                        onPressed: () {
                                          //TODO:
                                          audioManager.isPlaying = false;
                                          audioManager.pause();
                                        },
                                      );
                            }
                          },
                        ),
                      ],
                    );
                  }),
            ),
          ),
        ),
      ),
    );
  }
}
