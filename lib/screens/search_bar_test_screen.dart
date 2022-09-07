import 'package:flutter/material.dart';

class SearchBarTestScreen extends StatelessWidget {
  SearchBarTestScreen({Key? key}) : super(key: key);

  final _isSearchMode = ValueNotifier<bool>(false);
  final _searchBarController = TextEditingController();
  final focusNode = FocusNode();

  // bu deviceWidth geçici atama
  final deviceWidth = 360.0;
  final deviceHeight = 640.0;

  //AnimatedContainerlar çalışması için fixed boyutlar lazım
  //Uygulama açılışında MediaQuery çağır
  //Constants'a at, ordan çek

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  AppBar customAppBar(BuildContext context) {
    return AppBar(
      leadingWidth: 26,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
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
                    width: value ? (deviceWidth - 110) : 0,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        style: const TextStyle(color: Colors.black),
                        controller: _searchBarController,
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
                right: deviceWidth / 2,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: value ? 0.0 : 1.0,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      'Etkinlikler',
                      style: TextStyle(
                        fontSize: 18,
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
                    child: IconButton(
                      onPressed: () {
                        _isSearchMode.value = !_isSearchMode.value;
                        if (_isSearchMode.value) {
                          // Searchbar açılış fonksiyonu
                          focusNode.requestFocus();
                        } else {
                          // Searchbar kapanış fonksiyonu
                          _searchBarController.clear();
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                      icon: Icon(value ? Icons.close : Icons.search),
                      iconSize: 26,
                      color: value ? Colors.red : Colors.black,
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
                      onPressed: () {
                        // Filtre button fonksiyonu
                        showModalBottomSheet<dynamic>(
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => customBottomSheet(context),
                        );
                      },
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
    );
  }

  Widget customBottomSheet(BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          height: deviceHeight - 100,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 26,
                    ),
                    iconSize: 12,
                  ),
                  const Spacer(),
                  const Text(
                    'Filtrele',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(
                    width: 40,
                  )
                ],
              ),
              const Divider(
                color: Colors.grey,
                height: 0.8,
              ),
              Form(
                child: Expanded(
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ara'),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.only(left: 8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.8,
                                ),
                              ),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  suffixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kategori'),
                            const SizedBox(height: 5),
                            Container(
                              height: 50,
                              padding: const EdgeInsets.only(left: 8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.8,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Object>(
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  hint: const Text(
                                    " Tümü",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  isExpanded: true,
                                  isDense: true,
                                  onChanged: (value) {
                                    //TODO:
                                  },
                                  items: const [
                                    //TODO:
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tür'),
                            const SizedBox(height: 5),
                            Container(
                              height: 50,
                              padding: const EdgeInsets.only(left: 8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.8,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Object>(
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  hint: const Text(
                                    " Tümü",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  isExpanded: true,
                                  isDense: true,
                                  onChanged: (value) {
                                    //TODO:
                                  },
                                  items: const [
                                    //TODO:
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ücret'),
                            const SizedBox(height: 5),
                            Container(
                              height: 50,
                              padding: const EdgeInsets.only(left: 8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 0.8,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Object>(
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  hint: const Text(
                                    " Tümü",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  isExpanded: true,
                                  isDense: true,
                                  onChanged: (value) {
                                    //TODO:
                                  },
                                  items: const [
                                    //TODO:
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                primary: Colors.lightBlue,
                              ),
                              child: const Text(
                                'Filtrele',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: OutlinedButton(
                            style: ElevatedButton.styleFrom(
                              side: const BorderSide(width: 1.0, color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                            onPressed: () {},
                            child: const Text(
                              'Filtreyi Sıfırla',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
