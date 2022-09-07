import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

import 'package:firebase_chat_example/constants.dart';

final mapService = MapService();

//** INFO: Code in the map screen should be like this to initialize this service */
//Consumer<MapService>(
// builder: (_, map, __) => GoogleMap(
//   onMapCreated: (controller) {
//     map.mapController = controller;
//   },
//** */

class MapService with ChangeNotifier {
  var isFabOpen = false;
  var flag = true;
  var spamClick = true;
  var spamCheck = false;
  var spamLocation = true;
  var isTargetMode = false;
  var isTrafficEnabled = false;
  var isPageLoading = true;
  var isFindingRoute = false;
  var isSearchMode = false;
  var selectedIndex = 1;
  var selectedTravelMode = TravelMode.driving;

  late GoogleMapController mapController;
  final GooglePlace googlePlace = GooglePlace(googleMapsApiKey);

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  LatLng centerScreen = const LatLng(40.9878681, 29.0367217);
  LatLng markerLocation = const LatLng(40.9878681, 29.0367217);

  List<AutocompletePrediction> predictions = [];

  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  late PolylinePoints polylinePoints;
  double totalDistance = 0;

  void toggleFab() {
    isFabOpen = !isFabOpen;
  }

  void updateCenterScreen(LatLng latLng) {
    centerScreen = latLng;
    notifyListeners();
  }

  void mapOnLongPressHandler(LatLng latLng) {
    if (isSearchMode) {
      simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    markerLocation = latLng;
    addMarker(latLng);
  }

  void addMarker(LatLng latLng) {
    //Remove this line if you want multiple markers
    markers.clear();
    polylineCoordinates.clear();
    polylines.clear();
    //

    var markerIdVal = myWayToGenerateId();
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
    markers[markerId] = marker;
    notifyListeners();
  }

  void onSelect(int index) {
    selectedIndex = index;
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

  Future<void> createPolylines(double destLat, double destLong, BuildContext context) async {
    isFindingRoute = true;
    notifyListeners();
    polylineCoordinates.clear();
    polylines.clear();

    polylinePoints = PolylinePoints();
    loc.LocationData currentLocation = await loc.Location().getLocation();
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
      totalDistance += calculateDistance(
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
    polylines[id] = polyline;
    isFindingRoute = false;
    notifyListeners();
  }

  void mapButtonHandler(BuildContext context) async {
    if (isSearchMode) {
      simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    isTargetMode = false;
    notifyListeners();
    var currentLocation = await loc.Location().getLocation();

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
            100,
          ),
        );
      } else {
        SchedulerBinding.instance.addPostFrameCallback(
          (_) {
            createPolylines(markerLocation.latitude, markerLocation.longitude, context).then(
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

  void navigationButtonHandler() async {
    if (isSearchMode) {
      simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    isTargetMode = false;
    notifyListeners();

    if (polylines.isNotEmpty) {
      var currentLocation = await loc.Location().getLocation();
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

  void deleteButtonHandler() async {
    markers.clear();
    polylineCoordinates.clear();
    polylines.clear();
    Future.delayed(const Duration(milliseconds: 500)).then(
      (_) => totalDistance = 0,
    );
    notifyListeners();
  }

  void targetModeButtonHandler() {
    if (isSearchMode) {
      simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    isTargetMode = !isTargetMode;
    notifyListeners();
  }

  void trafficButtonHandler() {
    isTrafficEnabled = !isTrafficEnabled;
    notifyListeners();
  }

  void searchButtonHandler() {
    isSearchMode = !isSearchMode;
    notifyListeners();
  }

  void animateToLocation({required LatLng latLng, double zoom = 14.0, double tilt = 0.0}) async {
    if (isSearchMode) {
      simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    isTargetMode = false;
    notifyListeners();

    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: zoom,
          tilt: tilt,
          target: latLng,
        ),
      ),
    );
  }

  Future<loc.LocationData?> tryGetCurrentLocation() async {
    var status = await loc.Location().hasPermission();

    if (status == loc.PermissionStatus.denied) {
      var value = await loc.Location().requestPermission();

      if (value == loc.PermissionStatus.granted) {
        var currentLocation = await loc.Location().getLocation();

        return currentLocation;
      } else {
        return null;
      }
    } else {
      var currentLocation = await loc.Location().getLocation();
      return currentLocation;
    }
  }

  Future<LatLng> getLatLng(String? placeId) async {
    DetailsResult? detailsResult;
    var response = await googlePlace.details.get(placeId ?? '');
    if (response != null && response.result != null) {
      detailsResult = response.result;
    }

    return LatLng(
        detailsResult?.geometry?.location?.lat ?? 0, detailsResult?.geometry?.location?.lng ?? 0);
  }

  void simulateClickFunction({duration = Duration.zero, required Offset clickPosition}) async {
    if (duration == Duration.zero) {
      GestureBinding.instance.handlePointerEvent(PointerDownEvent(
        position: clickPosition,
      ));
      Future.delayed(
        duration,
        () {
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(
            position: clickPosition,
          ));
        },
      );
    } else {
      if (spamClick) {
        spamClick = false;
        GestureBinding.instance.handlePointerEvent(PointerDownEvent(
          position: clickPosition,
        ));
        Future.delayed(
          duration,
          () {
            GestureBinding.instance.handlePointerEvent(PointerUpEvent(
              position: clickPosition,
            ));
            spamClick = true;
          },
        );
      }
    }
  }

  void autoCompleteSearch(String value) async {
    if (spamCheck == false) {
      var result = await googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null) {
        predictions = result.predictions as List<AutocompletePrediction>;
        notifyListeners();
      }
      spamCheck = true;

      Future.delayed(
        const Duration(seconds: 1),
        () async {
          spamCheck = false;
          var result = await googlePlace.autocomplete.get(value);
          if (result != null && result.predictions != null) {
            predictions = result.predictions as List<AutocompletePrediction>;
            notifyListeners();
          }
        },
      );
    }
  }

  Future<bool> tryGetPermission() async {
    var value = await loc.Location().requestPermission();
    if (value == loc.PermissionStatus.granted) {
      return true;
    }
    return false;
  }

  Future<bool> tryGetLocationService() async {
    var isEnabled = await loc.Location().serviceEnabled();
    if (isEnabled) {
      return true;
    }
    var value = await loc.Location().requestService();
    if (value) {
      return true;
    }
    return false;
  }

  String myWayToGenerateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
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

  void disposeFunction() {
    markers.clear();
    polylineCoordinates.clear();
    polylines.clear();
    totalDistance = 0;
    mapController.dispose();
  }
}
