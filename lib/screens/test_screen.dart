import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:charts_flutter/flutter.dart' as charts;

import 'package:firebase_chat_example/widgets/alert_dialog.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/custom_loading.dart';
import 'package:firebase_chat_example/widgets/error_message.dart';
import 'package:firebase_chat_example/widgets/exit_popup.dart';

class TestScreen extends StatelessWidget {
  TestScreen({Key? key}) : super(key: key);

  final int selectedIndex = 0;
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);

  final PageController _pageController = PageController(initialPage: 0);
  static List<Widget> pages = [
    const TestHome(),
    const TestChart(),
    const TestSettings(),
    const TestCode(),
    const TestClick(),
  ];

  void onSelect(int index) {
    _selectedIndex.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.amber,
        ),
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () {
                    showMyDialog(
                      context,
                      true,
                      'Dont press here',
                      'This does nothing yet, but click if you want, idc',
                      '',
                      'Uhm ok...',
                      () {
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  icon: const Icon(Icons.build_sharp)),
            ],
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: onSelect,
            children: pages,
          ),
          drawer: const AppDrawer(),
          bottomNavigationBar: ValueListenableBuilder(
              valueListenable: _selectedIndex,
              builder: (_, int value, __) {
                return BottomNavigationBar(
                  type: BottomNavigationBarType.shifting,
                  selectedItemColor: Colors.amber,
                  unselectedItemColor: Colors.grey,
                  onTap: (index) {
                    //
                    _pageController.animateToPage(index,
                        duration: const Duration(milliseconds: 500), curve: Curves.ease);
                  },
                  currentIndex: value,
                  elevation: 10,
                  showUnselectedLabels: false,
                  items: const [
                    BottomNavigationBarItem(
                      backgroundColor: Colors.black87,
                      label: 'Home',
                      icon: Icon(Icons.home),
                    ),
                    BottomNavigationBarItem(
                      label: 'Bar Chart',
                      icon: Icon(Icons.bar_chart),
                    ),
                    BottomNavigationBarItem(
                      label: 'Settings',
                      icon: Icon(Icons.settings),
                    ),
                    BottomNavigationBarItem(
                      label: 'Code',
                      icon: Icon(Icons.code),
                    ),
                    BottomNavigationBarItem(
                      label: 'ClickTest',
                      icon: Icon(Icons.mouse),
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }
}

//Navigation bar pages;
class TestHome extends StatelessWidget {
  const TestHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('data'),
                      Text('data'),
                    ],
                  ),
                  Expanded(child: Container()),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('button'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                color: Colors.black54,
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Center(
                            child: Text('data2'),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('button2'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Center(child: Text('data3')),
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
                      height: 300,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Center(child: Text('data3')),
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
    );
  }
}

class TestChart extends StatelessWidget {
  const TestChart({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 1),
        Expanded(
          flex: 16,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      'data or something',
                      style: TextStyle(color: Colors.white),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.amber,
                      ),
                      onPressed: () {},
                      child: const Text(
                        'button here',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(flex: 1),
        Expanded(
          flex: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black54,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const SizedBox(
                  height: 30,
                ),
                Card(
                  elevation: 5,
                  child: SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.bar_chart_rounded, size: 40),
                        ),
                        const Text('Temp Data Text Here', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.amber,
                            ),
                            onPressed: () {},
                            child: const Text(
                              'button4',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // charts_flutter package throws nullcheck warning, disabled for now

                // SizedBox(
                //   height: 400,
                //   child: InkWell(
                //     onTap: () {},
                //     child: DataChart(
                //       data: data,
                //     ),
                //   ),
                // ),
                Row(
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.amber,
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Does Something',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TestSettings extends StatelessWidget {
  const TestSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<double> turns = ValueNotifier<double>(0.0);

    void _changeRotation() {
      turns.value += 4.0 / 8.0;
    }

    return ListView(
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              const Text(
                'Under Construction',
                style: TextStyle(fontSize: 30),
              ),
              ValueListenableBuilder(
                valueListenable: turns,
                builder: (_, double value, __) {
                  return AnimatedRotation(
                    alignment: Alignment.center,
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOut,
                    turns: value,
                    child: IconButton(
                      iconSize: 150,
                      onPressed: () {
                        _changeRotation();
                        errorMessage(
                          context,
                          'Dont press on me ffs -_-',
                          'Ok, sorry',
                          () {},
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.construction,
                      ),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(150),
                ),
                width: 150,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(150),
                  child: const ColorLoader2(
                    color1: Colors.amber,
                    color2: Colors.black,
                    color3: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TestCode extends StatelessWidget {
  const TestCode({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              const Text(
                'Also Under Construction',
                style: TextStyle(fontSize: 30),
              ),
              IconButton(
                iconSize: 150,
                onPressed: () {
                  errorMessage(
                    context,
                    'Dont press on me yet',
                    '',
                    () {},
                    true,
                  );
                },
                icon: const Icon(
                  Icons.construction,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TestClick extends StatelessWidget {
  const TestClick({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool spamFlag = true;

    Future<void> spamCheckFunction({
      required Duration duration,
      required Offset clickPosition,
    }) async {
      if (spamFlag) {
        spamFlag = false;
        GestureBinding.instance.handlePointerEvent(PointerDownEvent(
          position: clickPosition,
        ));
        Future.delayed(duration).then((_) {
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(
            position: clickPosition,
          ));
          spamFlag = true;
        });
      }
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Tap screen simulate test with GestureBinding',
            style: TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            primary: Colors.black,
          ),
          child: const SizedBox(
            width: 300,
            height: 300,
            child: Center(child: Text("Big button.")),
          ),
        ),
        ElevatedButton(
          onPressed: () => spamCheckFunction(
            duration: const Duration(milliseconds: 500),
            clickPosition: const Offset(200, 300),
          ),
          child: const Text('Simulate Click'),
        ),
      ],
    );
  }
}



// //Chart's data class
// class DataType {
//   final String data1;
//   final int data2;
//   final charts.Color barColor;

//   DataType({required this.data1, required this.data2, required this.barColor});
// }

// //Chart's dummy data list
// final List<DataType> data = [
//   DataType(
//     data1: "2008",
//     data2: 2000,
//     barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   ),
//   DataType(
//     data1: "2009",
//     data2: 11000,
//     barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   ),
//   DataType(
//     data1: "2010",
//     data2: 12000,
//     barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   ),
//   DataType(
//     data1: "2011",
//     data2: 5000,
//     barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   ),
//   DataType(
//     data1: "2012",
//     data2: 8500,
//     barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   ),
//   // DataType(
//   //   data1: "2013",
//   //   data2: 7700,
//   //   barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   // ),
//   // DataType(
//   //   data1: "2014",
//   //   data2: 7600,
//   //   barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   // ),
//   // DataType(
//   //   data1: "2015",
//   //   data2: 9500,
//   //   barColor: charts.ColorUtil.fromDartColor(Colors.blueAccent),
//   // ),
// ];

// class DataChart extends StatelessWidget {
//   const DataChart({super.key, required this.data});
//   final List<DataType> data;

//   @override
//   Widget build(BuildContext context) {
//     List<charts.Series<DataType, String>> series = [
//       charts.Series(
//         id: "developers",
//         data: data,
//         domainFn: (DataType series, _) => series.data1,
//         measureFn: (DataType series, _) => series.data2,
//         colorFn: (DataType series, _) => series.barColor,
//       )
//     ];
//     return Card(
//       elevation: 15,
//       color: Colors.grey[850],
//       child: Padding(
//         padding: const EdgeInsets.all(15.0),
//         child: charts.BarChart(
//           defaultRenderer:
//               charts.BarRendererConfig(cornerStrategy: const charts.ConstCornerStrategy(5)),
//           selectionModels: [
//             charts.SelectionModelConfig(
//               type: charts.SelectionModelType.info,
//               changedListener: (model) {
//                 //what to do when you click a bar
//                 final selectedDatum = model.selectedDatum;
//                 if (selectedDatum.isNotEmpty) {
//                   errorMessage(
//                     context,
//                     selectedDatum.first.datum.data2.toString(),
//                     selectedDatum.first.datum.data1,
//                     () {},
//                     true,
//                   );
//                 }
//               },
//             ),
//           ],
//           series,
//           animate: true,
//           animationDuration: const Duration(milliseconds: 600),
//           primaryMeasureAxis: const charts.NumericAxisSpec(
//             renderSpec: charts.GridlineRendererSpec(
//               labelStyle: charts.TextStyleSpec(
//                 fontSize: 12,
//                 color: charts.MaterialPalette.white,
//               ),
//             ),
//           ),
//           domainAxis: const charts.OrdinalAxisSpec(
//             renderSpec: charts.SmallTickRendererSpec(
//               labelStyle: charts.TextStyleSpec(
//                 fontSize: 11,
//                 color: charts.MaterialPalette.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // safearea>column>expanded>listview dene bi ara