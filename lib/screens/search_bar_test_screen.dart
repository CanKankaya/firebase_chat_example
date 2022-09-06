import 'package:flutter/material.dart';

import 'package:firebase_chat_example/constants.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/custom_icon_button.dart';
import 'package:firebase_chat_example/widgets/simpler_custom_loading.dart';

class SearchBarTestScreen extends StatelessWidget {
  SearchBarTestScreen({Key? key}) : super(key: key);

  final ValueNotifier<bool> _isSearchMode = ValueNotifier<bool>(false);

  //INFO: AnimatedContainerlar çalışması için fixed boyut lazım, Uygulama açılışında MediaQuery çağır, bi constanta ata

  @override
  Widget build(BuildContext context) {
    var focusNode = FocusNode();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 26,
          ),
          iconSize: 12,
        ),
        backgroundColor: Colors.grey[300],
        title: ValueListenableBuilder(
          valueListenable: _isSearchMode,
          builder: (_, bool value, __) {
            return Stack(
              children: [
                Row(
                  children: [
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: value ? deviceWidth - 140 : 0,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Ara...',
                            hintStyle: TextStyle(color: value ? Colors.grey : Colors.transparent),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
                Positioned(
                  right: 130,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: value ? 0.0 : 1.0,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Etkinlikler',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      color: Colors.white,
                      height: 40,
                      width: 40,
                      child: CustomIconButton(
                        buttonFon: () {
                          _isSearchMode.value = !_isSearchMode.value;
                          if (_isSearchMode.value) {
                            focusNode.requestFocus();
                          } else {
                            FocusManager.instance.primaryFocus?.unfocus();
                          }
                        },
                        icon: AnimatedIcons.search_ellipsis,
                        iconSize: 26,
                        iconColor: Colors.black,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: Colors.white,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.filter_alt,
                          color: Colors.black,
                          size: 26,
                        ),
                        iconSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: const [
          Expanded(
            child: SimplerCustomLoader(),
          ),
        ],
      ),
    );
  }
}
