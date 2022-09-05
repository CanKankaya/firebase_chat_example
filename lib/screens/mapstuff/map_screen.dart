import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

import 'package:firebase_chat_example/constants.dart';
import 'package:firebase_chat_example/services/map_service.dart';

import 'package:firebase_chat_example/widgets/simpler_custom_loading.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/expandable_fab.dart';
import 'package:firebase_chat_example/widgets/custom_icon_button.dart';

import 'package:firebase_chat_example/screens/no_internet_screen.dart';
import 'package:firebase_chat_example/screens/mapstuff/map_denied_screen.dart';
import 'package:firebase_chat_example/screens/mapstuff/place_detail_screen.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (mapService.isPageLoading) {
      return WillPopScope(
        onWillPop: _onWillPopHandler,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(),
          drawer: const AppDrawer(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Trying to get user location...',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SimplerCustomLoader(),
            ],
          ),
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: _onWillPopHandler,
        child: Scaffold(
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
                  onMapCreated: map.onMapCreated,
                  trafficEnabled: map.isTrafficEnabled,
                  myLocationEnabled: true,
                  mapToolbarEnabled: false,
                  buildingsEnabled: false,
                  compassEnabled: true,
                  initialCameraPosition: CameraPosition(zoom: 14, target: map.centerScreen),
                  markers: Set<Marker>.of(map.markers.values),
                  polylines: Set<Polyline>.of(map.polylines.values),
                  onTap: null,
                  onLongPress: _mapOnLongPressHandler,
                  onCameraMove: null,
                  onCameraIdle: () async {
                    if (map.isTargetMode && map.flag) {
                      map.markerLocation = await map.mapController.getLatLng(
                        ScreenCoordinate(
                          x: middleX,
                          y: middleY,
                        ),
                      );

                      _addMarker(map.markerLocation);
                    }
                  },
                ),
              ),
              Positioned(
                child: Padding(
                  padding: const EdgeInsets.only(left: 60.0, top: 8.0, bottom: 8.0, right: 60.0),
                  child: _buildHeadWidget(context),
                ),
              ),
              if (mapService.isTargetMode)
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    color: Colors.lightBlue.withOpacity(0.1),
                    child: Center(
                      child: Theme(
                        data: ThemeData.light(),
                        child: const Icon(
                          Icons.control_point,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                child: _buildSearchSheet(),
              ),
            ],
          ),
          floatingActionButton: _buildExpandableFab(),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    //**These are temporary assignments in case current user location is not found */
    mapService.centerScreen = const LatLng(40.9878681, 29.0367217);
    mapService.markerLocation = const LatLng(40.9878681, 29.0367217);
    //** */

    mapService.checkInternet().then((value) {
      if (value) {
        mapService.tryGetCurrentLocation().then((value) {
          if (value == null) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MapDeniedScreen(),
                ));
            return;
          }

          mapService.centerScreen = LatLng(value.latitude ?? 0, value.longitude ?? 0);
          SchedulerBinding.instance.addPostFrameCallback((_) {
            deviceWidth = MediaQuery.of(context).size.width;
            deviceHeight = MediaQuery.of(context).size.height;
            screenWidth = deviceWidth * MediaQuery.of(context).devicePixelRatio;
            screenHeight = deviceHeight * MediaQuery.of(context).devicePixelRatio;
            middleX = (screenWidth / 2).round();
            middleY = ((screenHeight / 2) - 120).round();
            setState(() {
              mapService.isPageLoading = false;
            });
          });
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NoInternetScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    mapService.markers.clear();
    mapService.polylineCoordinates.clear();
    mapService.polylines.clear();
    mapService.totalDistance = 0;
    mapService.mapController.dispose();

    super.dispose();
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

  Future<void> _createPolylines(double destLat, double destLong, BuildContext context) async {
    setState(() {
      mapService.isFindingRoute = true;
    });
    mapService.polylineCoordinates.clear();
    mapService.polylines.clear();

    mapService.polylinePoints = PolylinePoints();
    loc.LocationData currentLocation = await loc.Location().getLocation();
    double startLatitude = currentLocation.latitude ?? 0;
    double startLongitude = currentLocation.longitude ?? 0;

    PolylineResult result = await mapService.polylinePoints.getRouteBetweenCoordinates(
      googleMapsApiKey,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destLat, destLong),
      travelMode: mapService.selectedTravelMode,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        mapService.polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    mapService.totalDistance = 0.0;
    for (var i = 0; i < mapService.polylineCoordinates.length - 1; i++) {
      mapService.totalDistance += mapService.calculateDistance(
          mapService.polylineCoordinates[i].latitude,
          mapService.polylineCoordinates[i].longitude,
          mapService.polylineCoordinates[i + 1].latitude,
          mapService.polylineCoordinates[i + 1].longitude);
    }
    if (mapService.totalDistance == 0.0) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
          ),
        );
      });
    }

    var id = const PolylineId('poly');

    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.lightBlue,
      points: mapService.polylineCoordinates,
      width: 5,
    );
    setState(() {
      mapService.polylines[id] = polyline;
      mapService.isFindingRoute = false;
    });
  }

  void _addMarker(LatLng latLng) {
    //Remove this line if you want multiple markers
    mapService.markers.clear();
    mapService.polylineCoordinates.clear();
    mapService.polylines.clear();
    //

    var markerIdVal = mapService.myWayToGenerateId();
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: latLng,
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      onTap: () async {
        mapService.flag = false;
        await Future.delayed(const Duration(milliseconds: 500));
        mapService.flag = true;
      },
    );
    setState(() {
      mapService.markers[markerId] = marker;
    });
  }

  void _animateToLocation({required LatLng latLng, double zoom = 14.0, double tilt = 0.0}) async {
    if (mapService.isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    setState(() {
      mapService.isTargetMode = false;
    });
    mapService.mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          tilt: tilt,
          target: mapService.markerLocation,
        ),
      ),
    );
  }

  void _mapButtonHandler() async {
    if (mapService.isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    setState(() {
      mapService.isTargetMode = false;
    });
    var currentLocation = await loc.Location().getLocation();

    if (mapService.markers.isNotEmpty && !mapService.isFindingRoute) {
      if (mapService.polylines.isNotEmpty) {
        mapService.mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                  ((currentLocation.latitude ?? 0) <= mapService.markerLocation.latitude
                          ? currentLocation.latitude
                          : mapService.markerLocation.latitude) ??
                      0,
                  ((currentLocation.longitude ?? 0) <= mapService.markerLocation.longitude
                          ? currentLocation.longitude
                          : mapService.markerLocation.longitude) ??
                      0),
              northeast: LatLng(
                  ((currentLocation.latitude ?? 0) <= mapService.markerLocation.latitude
                          ? mapService.markerLocation.latitude
                          : currentLocation.latitude) ??
                      0,
                  ((currentLocation.longitude ?? 0) <= mapService.markerLocation.longitude
                          ? mapService.markerLocation.longitude
                          : currentLocation.longitude) ??
                      0),
            ),
            100,
          ),
        );
      } else {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) {
            _createPolylines(mapService.markerLocation.latitude,
                    mapService.markerLocation.longitude, context)
                .then(
              (_) async {
                if (currentLocation.latitude == null ||
                    currentLocation.latitude == 0 ||
                    currentLocation.longitude == null ||
                    currentLocation.longitude == 0) {
                  return;
                }
                mapService.mapController.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(
                          ((currentLocation.latitude ?? 0) <= mapService.markerLocation.latitude
                                  ? currentLocation.latitude
                                  : mapService.markerLocation.latitude) ??
                              0,
                          ((currentLocation.longitude ?? 0) <= mapService.markerLocation.longitude
                                  ? currentLocation.longitude
                                  : mapService.markerLocation.longitude) ??
                              0),
                      northeast: LatLng(
                          ((currentLocation.latitude ?? 0) <= mapService.markerLocation.latitude
                                  ? mapService.markerLocation.latitude
                                  : currentLocation.latitude) ??
                              0,
                          ((currentLocation.longitude ?? 0) <= mapService.markerLocation.longitude
                                  ? mapService.markerLocation.longitude
                                  : currentLocation.longitude) ??
                              0),
                    ),
                    100,
                  ),
                );
              },
            );
          },
        );
      }
    }
  }

  void _navigationButtonHandler() async {
    if (mapService.isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    setState(() {
      mapService.isTargetMode = false;
    });

    if (mapService.polylines.isNotEmpty) {
      var currentLocation = await loc.Location().getLocation();
      if (currentLocation.latitude == null ||
          currentLocation.latitude == 0 ||
          currentLocation.longitude == null ||
          currentLocation.longitude == 0) {
        return;
      }

      mapService.mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            zoom: 17,
            tilt: 55,
            target: LatLng(currentLocation.latitude ?? 0, currentLocation.longitude ?? 0),
          ),
        ),
      );
    }
  }

  void _mapOnLongPressHandler(LatLng latLng) {
    if (mapService.isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    mapService.markerLocation = latLng;
    _addMarker(latLng);
  }

  void _autoCompleteSearch(String value) async {
    if (mapService.spamCheck == false) {
      var result = await mapService.googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null && mounted) {
        setState(() {
          mapService.predictions = result.predictions as List<AutocompletePrediction>;
        });
      }
      mapService.spamCheck = true;
      Future.delayed(
        const Duration(seconds: 2),
        () async {
          mapService.spamCheck = false;
          var result = await mapService.googlePlace.autocomplete.get(value);
          if (result != null && result.predictions != null && mounted) {
            setState(() {
              mapService.predictions = result.predictions as List<AutocompletePrediction>;
            });
          }
        },
      );
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
                                  _createPolylines(
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
                                  _createPolylines(
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
                                  _createPolylines(
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
                                  _createPolylines(
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

  Widget _buildExpandableFab() {
    return Consumer<MapService>(
      builder: (_, map, __) => ExpandableFab(
        alignment: Alignment.bottomLeft,
        distance: 140.0,
        smallDistance: 80.0,
        children: [
          ActionButton(
            isSmall: true,
            onPressed: map.deleteButtonHandler,
            backgroundColor: Colors.black,
            icon: Icon(
              Icons.delete,
              color: map.markers.isNotEmpty ? Colors.amber : Colors.grey,
            ),
          ),
          ActionButton(
            onPressed: _navigationButtonHandler,
            backgroundColor: Colors.black,
            icon: Icon(
              Icons.navigation,
              color: map.polylines.isNotEmpty ? Colors.amber : Colors.grey,
            ),
          ),
          ActionButton(
            onPressed: _mapButtonHandler,
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
            isSmall: true,
            onPressed: () {},
            backgroundColor: Colors.black,
            icon: const Icon(
              Icons.construction,
              color: Colors.white,
            ),
          ),
          ActionButton(
            isSmall: true,
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

  Widget _buildSearchSheet() {
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
                      _autoCompleteSearch(value);
                    } else {
                      if (map.predictions.isNotEmpty && mounted) {
                        setState(() {
                          map.predictions = [];
                        });
                      }
                    }
                  },
                ),
              ),
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
                            _addMarker(map.markerLocation);
                            _animateToLocation(latLng: map.markerLocation);
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
