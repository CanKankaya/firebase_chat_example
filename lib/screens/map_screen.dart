import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:firebase_chat_example/constants.dart';
import 'package:firebase_chat_example/services/map_service.dart';

import 'package:firebase_chat_example/widgets/simpler_custom_loading.dart';
import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/expandable_fab.dart';

import 'package:firebase_chat_example/screens/map_denied_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  late GoogleMapController mapController;
  var flag = true;
  var isTargetMode = false;
  var isTrafficEnabled = false;
  var isPageLoading = true;
  var isFindingRoute = false;
  var selectedIndex = 1;
  var selectedTravelMode = TravelMode.driving;

//**These are temporary LatLngs in case current user location is not found */
  LatLng centerScreen = const LatLng(40.9878681, 29.0367217);
  LatLng markerLocation = const LatLng(40.9878681, 29.0367217);
  //** */

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  double totalDistance = 0;

  @override
  Widget build(BuildContext context) {
    if (isPageLoading) {
      return WillPopScope(
        onWillPop: onWillPopHandler,
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
        onWillPop: onWillPopHandler,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(),
          drawer: const AppDrawer(),
          body: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                trafficEnabled: isTrafficEnabled,
                myLocationEnabled: true,
                mapToolbarEnabled: false,
                buildingsEnabled: false,
                compassEnabled: true,
                initialCameraPosition: CameraPosition(zoom: 14, target: centerScreen),
                markers: Set<Marker>.of(markers.values),
                polylines: Set<Polyline>.of(polylines.values),
                onTap: (latLng) {
                  //
                },
                onLongPress: (latLng) {
                  markerLocation = latLng;
                  _addMarker(latLng);
                },
                onCameraMove: (position) {
                  //
                },
                onCameraIdle: () async {
                  if (isTargetMode && flag) {
                    markerLocation = await mapController.getLatLng(
                      ScreenCoordinate(
                        x: middleX,
                        y: middleY,
                      ),
                    );

                    _addMarker(markerLocation);
                  }
                },
              ),
              Positioned(
                child: Padding(
                  padding: const EdgeInsets.only(left: 60.0, top: 8.0, bottom: 8.0, right: 60.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Material(
                      color: Colors.black,
                      child: AnimatedContainer(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: polylines.isNotEmpty ? 80 : 0,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Total Distance: ${totalDistance.toStringAsFixed(2)} KM',
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
                                opacity: polylines.isNotEmpty ? 1.0 : 0.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: selectedIndex == 0
                                          ? null
                                          : () {
                                              onSelect(0);
                                              _createPolylines(
                                                markerLocation.latitude,
                                                markerLocation.longitude,
                                                context,
                                              );
                                            },
                                      icon: Icon(
                                        Icons.directions_bike,
                                        color: selectedIndex == 0 ? Colors.amber : Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: selectedIndex == 1
                                          ? null
                                          : () {
                                              onSelect(1);
                                              _createPolylines(
                                                markerLocation.latitude,
                                                markerLocation.longitude,
                                                context,
                                              );
                                            },
                                      icon: Icon(
                                        Icons.directions_car,
                                        color: selectedIndex == 1 ? Colors.amber : Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: selectedIndex == 2
                                          ? null
                                          : () {
                                              onSelect(2);
                                              _createPolylines(
                                                markerLocation.latitude,
                                                markerLocation.longitude,
                                                context,
                                              );
                                            },
                                      icon: Icon(
                                        Icons.directions_transit,
                                        color: selectedIndex == 2 ? Colors.amber : Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: selectedIndex == 3
                                          ? null
                                          : () {
                                              onSelect(3);
                                              _createPolylines(
                                                markerLocation.latitude,
                                                markerLocation.longitude,
                                                context,
                                              );
                                            },
                                      icon: Icon(
                                        Icons.directions_walk,
                                        color: selectedIndex == 3 ? Colors.amber : Colors.white,
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
                ),
              ),
              if (isTargetMode)
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
            ],
          ),
          floatingActionButton: ExpandableFab(
            distance: 150.0,
            children: [
              ActionButton(
                onPressed: () async {
                  setState(() {
                    markers.clear();
                    polylineCoordinates.clear();
                    polylines.clear();
                    Future.delayed(const Duration(milliseconds: 500)).then(
                      (_) => totalDistance = 0,
                    );
                  });
                },
                backgroundColor: Colors.black,
                icon: Icon(
                  Icons.delete,
                  color: markers.isNotEmpty ? Colors.amber : Colors.grey,
                ),
              ),
              ActionButton(
                onPressed: navigationButtonHandler,
                backgroundColor: Colors.black,
                icon: Icon(
                  Icons.navigation,
                  color: polylines.isNotEmpty ? Colors.amber : Colors.grey,
                ),
              ),
              ActionButton(
                onPressed: mapButtonHandler,
                backgroundColor: Colors.black,
                icon: isFindingRoute
                    ? const SimplerCustomLoader()
                    : Icon(
                        Icons.map,
                        color: markers.isNotEmpty ? Colors.amber : Colors.grey,
                      ),
              ),
              ActionButton(
                onPressed: () {
                  setState(() {
                    isTrafficEnabled = !isTrafficEnabled;
                  });
                },
                backgroundColor: isTrafficEnabled ? Colors.blue : Colors.black,
                icon: Icon(
                  Icons.traffic,
                  color: isTrafficEnabled ? Colors.black : Colors.amber,
                ),
              ),
              ActionButton(
                onPressed: () {
                  setState(() {
                    isTargetMode = !isTargetMode;
                  });
                },
                backgroundColor: isTargetMode ? Colors.blue : Colors.black,
                icon: Icon(
                  Icons.control_point,
                  color: isTargetMode ? Colors.black : Colors.amber,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    MapService().tryGetCurrentLocation().then((value) {
      if (value == null) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MapDeniedScreen(),
            ));
        return;
      }

      centerScreen = LatLng(value.latitude ?? 0, value.longitude ?? 0);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        screenWidth = MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio;
        screenHeight = MediaQuery.of(context).size.height * MediaQuery.of(context).devicePixelRatio;
        middleX = (screenWidth / 2).round();
        middleY = ((screenHeight / 2) - 120).round();
        setState(() {
          isPageLoading = false;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    markers.clear();
    polylineCoordinates.clear();
    polylines.clear();
    totalDistance = 0;
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

  void onSelect(int index) {
    setState(() {
      selectedIndex = index;
    });
    switch (index) {
      case 0:
        selectedTravelMode = TravelMode.bicycling;
        break;
      case 1:
        selectedTravelMode = TravelMode.driving;
        break;
      case 2:
        selectedTravelMode = TravelMode.transit;
        break;
      case 3:
        selectedTravelMode = TravelMode.walking;
        break;
    }
  }

  Future<void> _createPolylines(double destLat, double destLong, BuildContext context) async {
    setState(() {
      isFindingRoute = true;
    });
    polylineCoordinates.clear();
    polylines.clear();

    polylinePoints = PolylinePoints();
    LocationData currentLocation = await Location().getLocation();
    double startLatitude = currentLocation.latitude ?? 0;
    double startLongitude = currentLocation.longitude ?? 0;

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleMapsApiKey,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destLat, destLong),
      travelMode: selectedTravelMode,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    totalDistance = 0.0;
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += MapService().calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }
    if (totalDistance == 0.0) {
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
      points: polylineCoordinates,
      width: 5,
    );
    setState(() {
      polylines[id] = polyline;
      isFindingRoute = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addMarker(LatLng latLng) {
    //Remove this line if you want multiple markers
    markers.clear();
    polylineCoordinates.clear();
    polylines.clear();
    //

    var markerIdVal = MapService().myWayToGenerateId();
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: latLng,
      infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
      onTap: () async {
        flag = false;
        await Future.delayed(const Duration(milliseconds: 500));
        flag = true;
      },
    );
    setState(() {
      markers[markerId] = marker;
    });
  }

  void mapButtonHandler() async {
    isTargetMode = false;
    var currentLocation = await Location().getLocation();

    if (markers.isNotEmpty && !isFindingRoute) {
      if (polylines.isNotEmpty) {
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                  ((currentLocation.latitude ?? 0) <= markerLocation.latitude
                          ? currentLocation.latitude
                          : markerLocation.latitude) ??
                      0,
                  ((currentLocation.longitude ?? 0) <= markerLocation.longitude
                          ? currentLocation.longitude
                          : markerLocation.longitude) ??
                      0),
              northeast: LatLng(
                  ((currentLocation.latitude ?? 0) <= markerLocation.latitude
                          ? markerLocation.latitude
                          : currentLocation.latitude) ??
                      0,
                  ((currentLocation.longitude ?? 0) <= markerLocation.longitude
                          ? markerLocation.longitude
                          : currentLocation.longitude) ??
                      0),
            ),
            120,
          ),
        );
      } else {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) {
            _createPolylines(markerLocation.latitude, markerLocation.longitude, context).then(
              (_) async {
                if (currentLocation.latitude == null ||
                    currentLocation.latitude == 0 ||
                    currentLocation.longitude == null ||
                    currentLocation.longitude == 0) {
                  return;
                }
                mapController.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(
                          ((currentLocation.latitude ?? 0) <= markerLocation.latitude
                                  ? currentLocation.latitude
                                  : markerLocation.latitude) ??
                              0,
                          ((currentLocation.longitude ?? 0) <= markerLocation.longitude
                                  ? currentLocation.longitude
                                  : markerLocation.longitude) ??
                              0),
                      northeast: LatLng(
                          ((currentLocation.latitude ?? 0) <= markerLocation.latitude
                                  ? markerLocation.latitude
                                  : currentLocation.latitude) ??
                              0,
                          ((currentLocation.longitude ?? 0) <= markerLocation.longitude
                                  ? markerLocation.longitude
                                  : currentLocation.longitude) ??
                              0),
                    ),
                    120,
                  ),
                );
              },
            );
          },
        );
      }
    }
  }

  void navigationButtonHandler() async {
    setState(() {
      isTargetMode = false;
    });

    if (polylines.isNotEmpty) {
      var currentLocation = await Location().getLocation();
      if (currentLocation.latitude == null ||
          currentLocation.latitude == 0 ||
          currentLocation.longitude == null ||
          currentLocation.longitude == 0) {
        return;
      }

      mapController.animateCamera(
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
}
