import 'package:flutter/material.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({Key? key}) : super(key: key);

  //TODO: Try audio stuff here later

// FlutterSoundRecorder _recordingSession;
//   final recordingPlayer = AssetsAudioPlayer();
//   String pathToAudio;
//   bool _playAudio = false;
//   String _timerText = '00:00:00';
//   @override
//   void initState() {
//     super.initState();
//     initializer();
//   }
//    void initializer() async {
//     pathToAudio = '/sdcard/Download/temp.wav';
//     _recordingSession = FlutterSoundRecorder();
//     await _recordingSession.openAudioSession(
//         focus: AudioFocus.requestFocusAndStopOthers,
//         category: SessionCategory.playAndRecord,
//         mode: SessionMode.modeDefault,
//         device: AudioDevice.speaker);
//     await _recordingSession.setSubscriptionDuration(Duration(milliseconds: 10));
//     await initializeDateFormatting();
//     await Permission.microphone.request();
//     await Permission.storage.request();
//     await Permission.manageExternalStorage.request();
//   }

  ElevatedButton createElevatedButton({
    IconData? icon,
    Color? iconColor,
    Function()? onPressFunc,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(6.0),
        side: const BorderSide(
          color: Colors.amber,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        primary: Colors.black,
        elevation: 9.0,
      ),
      onPressed: onPressFunc,
      icon: Icon(
        icon,
        color: iconColor,
        size: 38.0,
      ),
      label: const Text(''),
    );
  }
// Future<void> startRecording() async {
//     Directory directory = Directory(path.dirname(pathToAudio));
//     if (!directory.existsSync()) {
//       directory.createSync();
//     }
//     _recordingSession.openAudioSession();
//     await _recordingSession.startRecorder(
//       toFile: pathToAudio,
//       codec: Codec.pcm16WAV,
//     );
//     StreamSubscription _recorderSubscription =
//         _recordingSession.onProgress.listen((e) {
//       var date = DateTime.fromMillisecondsSinceEpoch(e.duration.inMilliseconds,
//           isUtc: true);
//       var timeText = DateFormat('mm:ss:SS', 'en_GB').format(date);
//       setState(() {
//         _timerText = timeText.substring(0, 8);
//       });
//     });
//     _recorderSubscription.cancel();
//   }
//   Future<String> stopRecording() async {
//     _recordingSession.closeAudioSession();
//     return await _recordingSession.stopRecorder();
//   }
//   Future<void> playFunc() async {
//     recordingPlayer.open(
//       Audio.file(pathToAudio),
//       autoStart: true,
//       showNotification: true,
//     );
//   }
//   Future<void> stopPlayFunc() async {
//     recordingPlayer.stop();
//   }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: Scaffold(
        appBar: AppBar(),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    color: Colors.black54,
                    child: ListView(
                      padding: const EdgeInsets.all(10),
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              createElevatedButton(
                                icon: Icons.mic,
                                iconColor: Colors.amber,
                                onPressFunc: null,
                              ),
                              const SizedBox(width: 30),
                              createElevatedButton(
                                icon: Icons.stop,
                                iconColor: Colors.amber,
                                onPressFunc: null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(15.0),
                                child: Center(
                                  child: Text('data3'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.black,
                                    elevation: 10.0,
                                    shadowColor: Colors.amber,
                                  ),
                                  onPressed: () {},
                                  child: const Text('button3'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(15.0),
                                child: Center(
                                  child: Text('data3'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.black,
                                    elevation: 10.0,
                                    shadowColor: Colors.amber,
                                  ),
                                  onPressed: () {},
                                  child: const Text('button3'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
