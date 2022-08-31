import 'dart:developer';
import 'dart:math' as math;

import 'package:firebase_chat_example/constants.dart';
import 'package:firebase_chat_example/widgets/simpler_custom_loading.dart';
import 'package:flutter/material.dart';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'package:firebase_chat_example/widgets/app_drawer.dart';
import 'package:firebase_chat_example/widgets/expandable_fab.dart';

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

  LatLng centerScreen = const LatLng(40.9878681, 29.0367217);
  LatLng markerLocation = const LatLng(40.9878681, 29.0367217);
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  double totalDistance = 0;

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Future<void> _createPolylines(double destLat, double destLong) async {
    setState(() {
      isFindingRoute = true;
    });
    polylineCoordinates.clear();
    polylines.clear();
    Future.delayed(const Duration(milliseconds: 500)).then(
      (_) => totalDistance = 0,
    );

    log(isFindingRoute.toString());
    polylinePoints = PolylinePoints();
    LocationData currentLocation = await Location().getLocation();
    double startLatitude = currentLocation.latitude ?? 0;
    double startLongitude = currentLocation.longitude ?? 0;

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleMapsApiKey,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destLat, destLong),
      travelMode: TravelMode.transit,
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    for (var i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += calculateDistance(
          polylineCoordinates[i].latitude,
          polylineCoordinates[i].longitude,
          polylineCoordinates[i + 1].latitude,
          polylineCoordinates[i + 1].longitude);
    }
    log(totalDistance.toString());

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
      log(isFindingRoute.toString());
    });
  }

  _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  String _myWayToGenerateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _addMarker(LatLng latLng) {
    //Remove this line if you want multiple markers
    markers.clear();
    polylineCoordinates.clear();
    polylines.clear();
    //

    var markerIdVal = _myWayToGenerateId();
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

  Future<LocationData> _getCurrentLocation() async {
    // Delay is only here to test loading state, you can remove it
    await Future.delayed(const Duration(milliseconds: 1000));

    var currentLocation = await Location().getLocation();
    return currentLocation;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((value) {
      centerScreen = LatLng(value.latitude ?? 0, value.longitude ?? 0);
      setState(() {
        isPageLoading = false;
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

  @override
  Widget build(BuildContext context) {
    double screenWidth =
        MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio;
    double screenHeight =
        MediaQuery.of(context).size.height * MediaQuery.of(context).devicePixelRatio;

    int middleX = (screenWidth / 2).round();
    int middleY = ((screenHeight / 2) - 120).round();

    log('build function ran');
    if (isPageLoading) {
      return Scaffold(
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
      );
    } else {
      return WillPopScope(
        onWillPop: () {
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
        },
        child: Scaffold(
          appBar: AppBar(),
          drawer: const AppDrawer(),
          body: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                trafficEnabled: isTrafficEnabled,
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
                    var screenCoord = ScreenCoordinate(x: middleX, y: middleY);
                    markerLocation = await mapController.getLatLng(screenCoord);
                    log(markerLocation.latitude.toString());
                    log(markerLocation.longitude.toString());

                    _addMarker(markerLocation);
                  }
                },
              ),
              Positioned(
                child: Padding(
                  padding: const EdgeInsets.only(left: 60.0, top: 8.0, bottom: 8.0, right: 60.0),
                  child: AnimatedContainer(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.black,
                      boxShadow: [
                        if (polylines.isNotEmpty)
                          const BoxShadow(
                            color: Colors.grey,
                            spreadRadius: 5,
                            blurRadius: 7,
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 500),
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: polylines.isNotEmpty ? 60 : 0,
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
          floatingActionButton: Theme(
            data: ThemeData.dark(),
            child: ExpandableFab(
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
                  onPressed: () async {
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
                            target: LatLng(
                                currentLocation.latitude ?? 0, currentLocation.longitude ?? 0),
                          ),
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.black,
                  icon: Icon(
                    Icons.navigation,
                    color: polylines.isNotEmpty ? Colors.amber : Colors.grey,
                  ),
                ),
                ActionButton(
                  onPressed: () async {
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
                        _createPolylines(markerLocation.latitude, markerLocation.longitude).then(
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
                      }
                    }
                  },
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
        ),
      );
    }
  }
}
