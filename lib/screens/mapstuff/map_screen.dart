import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:firebase_chat_example/constants.dart';
import 'package:firebase_chat_example/services/map_service.dart';

import 'package:firebase_chat_example/widgets/simpler_custom_loading.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/expandable_fab.dart';
import 'package:firebase_chat_example/widgets/custom_icon_button.dart';

import 'package:firebase_chat_example/screens/mapstuff/no_service_screen.dart';
import 'package:firebase_chat_example/screens/mapstuff/no_internet_screen.dart';
import 'package:firebase_chat_example/screens/mapstuff/map_denied_screen.dart';
import 'package:firebase_chat_example/screens/mapstuff/place_detail_screen.dart';

class MapScreen extends StatelessWidget {
  MapScreen({Key? key}) : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final TextEditingController _searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    log('build method triggered');

    return FutureBuilder<bool>(
      future: mapService.checkInternet(),
      builder: (_, internetSnap) {
        if (internetSnap.connectionState == ConnectionState.waiting ||
            internetSnap.connectionState == ConnectionState.none) {
          return const Scaffold(
            body: Center(
              child: SimplerCustomLoader(),
            ),
          );
        }
        if (!internetSnap.data!) {
          return NoInternetScreen();
        }
        return FutureBuilder<bool>(
          future: mapService.tryGetLocationService(),
          builder: (context, serviceSnap) {
            if (serviceSnap.connectionState == ConnectionState.waiting ||
                serviceSnap.connectionState == ConnectionState.none) {
              return const Scaffold(
                body: Center(
                  child: SimplerCustomLoader(),
                ),
              );
            }
            if (!serviceSnap.data!) {
              return NoServiceScreen();
            }
            return FutureBuilder<bool>(
              future: mapService.tryGetPermission(),
              builder: (_, permissionSnap) {
                if (permissionSnap.connectionState == ConnectionState.waiting ||
                    permissionSnap.connectionState == ConnectionState.none) {
                  return const Scaffold(
                    body: Center(
                      child: SimplerCustomLoader(),
                    ),
                  );
                }
                if (!permissionSnap.data!) {
                  return MapDeniedScreen();
                }
                return FutureBuilder<LatLng?>(
                  future: initFunction(context),
                  builder: (_, futureSnap) {
                    if (futureSnap.connectionState == ConnectionState.waiting ||
                        futureSnap.connectionState == ConnectionState.none) {
                      return WillPopScope(
                        onWillPop: _onWillPopHandler,
                        child: Scaffold(
                          resizeToAvoidBottomInset: false,
                          appBar: AppBar(),
                          drawer: const AppDrawer(),
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SimplerCustomLoader(),
                                Text(
                                  'Finding your location...',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    var currentLocation = futureSnap.data;

                    return WillPopScope(
                      onWillPop: _onWillPopHandler,
                      child: Scaffold(
                        resizeToAvoidBottomInset: false,
                        key: _scaffoldKey,
                        appBar: AppBar(
                          actions: [
                            Consumer<MapService>(
                              builder: (_, map, __) => CustomIconButton(
                                iconSize: 32,
                                icon: AnimatedIcons.search_ellipsis,
                                buttonFon: map.searchButtonHandler,
                              ),
                            ),
                          ],
                        ),
                        drawer: const AppDrawer(),
                        body: Stack(
                          children: [
                            Consumer<MapService>(
                              builder: (_, map, __) => GoogleMap(
                                onMapCreated: (controller) {
                                  map.mapController = controller;
                                },
                                trafficEnabled: map.isTrafficEnabled,
                                myLocationEnabled: true,
                                mapToolbarEnabled: false,
                                buildingsEnabled: false,
                                compassEnabled: true,
                                initialCameraPosition: CameraPosition(
                                    zoom: 14, target: currentLocation ?? map.centerScreen),
                                markers: Set<Marker>.of(map.markers.values),
                                polylines: Set<Polyline>.of(map.polylines.values),
                                onTap: null,
                                onLongPress: map.mapOnLongPressHandler,
                                onCameraMove: null,
                                onCameraIdle: () async {
                                  if (map.isTargetMode && map.flag) {
                                    map.markerLocation = await map.mapController.getLatLng(
                                      ScreenCoordinate(
                                        x: middleX,
                                        y: middleY,
                                      ),
                                    );
                                    map.addMarker(map.markerLocation);
                                  }
                                },
                              ),
                            ),
                            Positioned(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 60.0,
                                  top: 8.0,
                                  bottom: 8.0,
                                  right: 60.0,
                                ),
                                child: _buildHeadWidget(context),
                              ),
                            ),
                            Consumer<MapService>(
                              builder: (_, map, __) => IgnorePointer(
                                ignoring: true,
                                child: map.isTargetMode
                                    ? Container(
                                        color: Colors.lightBlue.withOpacity(0.1),
                                        child: Center(
                                          child: Theme(
                                            data: ThemeData.light(),
                                            child: const Icon(
                                              Icons.control_point,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: _buildSearchSheet(context),
                            ),
                          ],
                        ),
                        floatingActionButton: _buildExpandableFab(context),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

//TODO: extract checks outside, run the futurebuilder AFTER all the local checks
  Future<LatLng?> initFunction(BuildContext context) async {
    log('init future ran');

    var locData = await mapService.tryGetCurrentLocation();
    if (locData == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MapDeniedScreen(),
          ),
        );
      });
      return null;
    } else {
      mapService.centerScreen = LatLng(locData.latitude ?? 0, locData.longitude ?? 0);

      log('init future finished');
      return LatLng(locData.latitude ?? 0, locData.longitude ?? 0);
    }
  }

  Future<bool> _onWillPopHandler() {
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

  Widget _buildHeadWidget(BuildContext context) {
    return Consumer<MapService>(
      builder: (_, map, __) => ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.black,
          child: AnimatedContainer(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            height: map.polylines.isNotEmpty ? 80 : 0,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Total Distance: ${map.totalDistance.toStringAsFixed(2)} KM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: map.polylines.isNotEmpty ? 1.0 : 0.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: map.selectedIndex == 0
                              ? null
                              : () {
                                  map.onSelect(0);
                                  map.createPolylines(
                                    map.markerLocation.latitude,
                                    map.markerLocation.longitude,
                                    context,
                                  );
                                },
                          icon: Icon(
                            Icons.directions_bike,
                            color: map.selectedIndex == 0 ? Colors.amber : Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: map.selectedIndex == 1
                              ? null
                              : () {
                                  map.onSelect(1);
                                  map.createPolylines(
                                    map.markerLocation.latitude,
                                    map.markerLocation.longitude,
                                    context,
                                  );
                                },
                          icon: Icon(
                            Icons.directions_car,
                            color: map.selectedIndex == 1 ? Colors.amber : Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: map.selectedIndex == 2
                              ? null
                              : () {
                                  map.onSelect(2);
                                  map.createPolylines(
                                    map.markerLocation.latitude,
                                    map.markerLocation.longitude,
                                    context,
                                  );
                                },
                          icon: Icon(
                            Icons.directions_transit,
                            color: map.selectedIndex == 2 ? Colors.amber : Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: map.selectedIndex == 3
                              ? null
                              : () {
                                  map.onSelect(3);
                                  map.createPolylines(
                                    map.markerLocation.latitude,
                                    map.markerLocation.longitude,
                                    context,
                                  );
                                },
                          icon: Icon(
                            Icons.directions_walk,
                            color: map.selectedIndex == 3 ? Colors.amber : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableFab(BuildContext context) {
    return Consumer<MapService>(
      builder: (_, map, __) => ExpandableFab(
        alignment: Alignment.bottomLeft,
        distance: 140.0,
        secondaryDistance: 80.0,
        children: [
          ActionButton(
            isSecondary: true,
            onPressed: map.deleteButtonHandler,
            backgroundColor: Colors.black,
            icon: Icon(
              Icons.delete,
              color: map.markers.isNotEmpty ? Colors.amber : Colors.grey,
            ),
          ),
          ActionButton(
            onPressed: map.navigationButtonHandler,
            backgroundColor: Colors.black,
            icon: Icon(
              Icons.navigation,
              color: map.polylines.isNotEmpty ? Colors.amber : Colors.grey,
            ),
          ),
          ActionButton(
            onPressed: () => map.mapButtonHandler(context),
            backgroundColor: Colors.black,
            icon: map.isFindingRoute
                ? const SimplerCustomLoader()
                : Icon(
                    Icons.map,
                    color: map.markers.isNotEmpty ? Colors.amber : Colors.grey,
                  ),
          ),
          ActionButton(
            onPressed: map.trafficButtonHandler,
            backgroundColor: map.isTrafficEnabled ? Colors.blue : Colors.black,
            icon: Icon(
              Icons.traffic,
              color: map.isTrafficEnabled ? Colors.black : Colors.amber,
            ),
          ),
          ActionButton(
            onPressed: map.targetModeButtonHandler,
            backgroundColor: map.isTargetMode ? Colors.blue : Colors.black,
            icon: Icon(
              Icons.control_point,
              color: map.isTargetMode ? Colors.black : Colors.amber,
            ),
          ),
          ActionButton(
            isSecondary: true,
            onPressed: () {},
            backgroundColor: Colors.black,
            icon: const Icon(
              Icons.construction,
              color: Colors.white,
            ),
          ),
          ActionButton(
            isSecondary: true,
            onPressed: () {},
            backgroundColor: Colors.black,
            icon: const Icon(
              Icons.construction,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSheet(BuildContext context) {
    return Consumer<MapService>(
      builder: (_, map, __) => AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
          color: map.isSearchMode ? Theme.of(context).secondaryHeaderColor : Colors.transparent,
        ),
        height: map.isSearchMode ? 250 : 0,
        width: deviceWidth,
        child: Column(
          children: [
            if (map.isSearchMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchTextController,
                  key: const ValueKey('searchText'),
                  decoration: const InputDecoration(
                    labelText: "Search",
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.blue,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black54,
                        width: 2.0,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      map.autoCompleteSearch(value);
                    } else {
                      if (map.predictions.isNotEmpty) {
                        map.predictions.clear();
                      }
                    }
                  },
                ),
              ),
            if (map.isSearchMode)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: ListView.builder(
                    itemCount: map.predictions.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        leading: Icon(
                          Icons.location_city,
                          color: map.isSearchMode ? Colors.white : Colors.transparent,
                        ),
                        title: Text(
                          map.predictions[i].description ?? 'No Description',
                          style: TextStyle(
                            color: map.isSearchMode ? null : Colors.transparent,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.pin_drop,
                            color: map.isSearchMode ? Colors.amber : Colors.transparent,
                          ),
                          onPressed: () async {
                            if (map.spamLocation) {
                              map.spamLocation = false;

                              map.markerLocation = await map.getLatLng(map.predictions[i].placeId);
                              map.addMarker(map.markerLocation);
                              map.animateToLocation(latLng: map.markerLocation);
                              Future.delayed(
                                const Duration(milliseconds: 1000),
                                () => map.spamLocation = true,
                              );
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaceDetailScreen(
                                placeId: map.predictions[i].placeId ?? '',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
