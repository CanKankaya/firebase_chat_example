import 'dart:io';

import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';

class ProgressBarState {
  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
  final Duration current;
  final Duration buffered;
  final Duration total;
}

enum ButtonState {
  paused,
  playing,
  loading,
}

//Example audio URL
var url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

class AudioManager {
  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final lastActiveIndex = ValueNotifier<int>(0);
  final initIcon = ValueNotifier<bool>(true);

  late AudioPlayer _audioPlayer;
  bool isInitializing = false;
  bool isPlaying = false;

  AudioManager() {
    init();
  }

  Future<void> changeUrl(String newUrl, int index) async {
    lastActiveIndex.value = index;

    if (url == newUrl) {
    } else {
      initIcon.value = false;
      buttonNotifier.value = ButtonState.loading;
      await _audioPlayer.pause();
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.dispose();
      url = newUrl;
      await init();
      buttonNotifier.value = ButtonState.paused;
    }
  }

  void play(int index) {
    _audioPlayer.play();
    lastActiveIndex.value = index;
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek({required Duration position, required int index, required String urlToChange}) {
    if (lastActiveIndex.value != index) {
      changeUrl(urlToChange, index);
    }
    _audioPlayer.seek(position);
  }

  Future<Duration> getDuration(String url) async {
    var tempPlayer = AudioPlayer();
    await tempPlayer.setUrl(url);
    var duration = tempPlayer.duration ?? Duration.zero;
    tempPlayer.dispose();
    return duration;
  }

  Future<bool> checkInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  void dispose() {
    if (!isInitializing) {
      _audioPlayer.dispose();
      initIcon.value = true;
    }
  }

  Future<void> init() async {
    try {
      buttonNotifier.value = ButtonState.loading;
      _audioPlayer = AudioPlayer();
      isInitializing = true;
      await _audioPlayer.setUrl(url);
      isInitializing = false;

      _audioPlayer.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          buttonNotifier.value = ButtonState.loading;
        } else if (!isPlaying) {
          buttonNotifier.value = ButtonState.paused;
        } else if (processingState != ProcessingState.completed) {
          buttonNotifier.value = ButtonState.playing;
        } else {
          _audioPlayer.pause();
          _audioPlayer.seek(Duration.zero);
        }
      });

      _audioPlayer.positionStream.listen((position) {
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: position,
          buffered: oldState.buffered,
          total: oldState.total,
        );
      });

      _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: oldState.current,
          buffered: bufferedPosition,
          total: oldState.total,
        );
      });

      _audioPlayer.durationStream.listen((totalDuration) {
        final oldState = progressNotifier.value;
        progressNotifier.value = ProgressBarState(
          current: oldState.current,
          buffered: oldState.buffered,
          total: totalDuration ?? Duration.zero,
        );
      });
      buttonNotifier.value = ButtonState.paused;
    } catch (e) {
      //TODO: error handling here

    }
  }
}
