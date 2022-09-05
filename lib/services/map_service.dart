import 'dart:io';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

import 'package:firebase_chat_example/constants.dart';

final mapService = MapService();

//TODO: Check conditions below;
//Permission not asked, location disabled
//Permission denied already, location disabled
//Permission granted, location enabled (works fine)
//Permission granted, location disabled

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

  late LatLng centerScreen;
  late LatLng markerLocation;

  List<AutocompletePrediction> predictions = [];

  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  late PolylinePoints polylinePoints;
  double totalDistance = 0;

  void toggleFab() {
    isFabOpen = !isFabOpen;
  }

  void onSelect(int index) {
    mapService.selectedIndex = index;
    switch (index) {
      case 0:
        mapService.selectedTravelMode = TravelMode.bicycling;
        break;
      case 1:
        mapService.selectedTravelMode = TravelMode.driving;
        break;
      case 2:
        mapService.selectedTravelMode = TravelMode.transit;
        break;
      case 3:
        mapService.selectedTravelMode = TravelMode.walking;
        break;
    }
  }

  void deleteButtonHandler() async {
    mapService.markers.clear();
    mapService.polylineCoordinates.clear();
    mapService.polylines.clear();
    Future.delayed(const Duration(milliseconds: 500)).then(
      (_) => mapService.totalDistance = 0,
    );
    notifyListeners();
  }

  void targetModeButtonHandler() {
    if (mapService.isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    mapService.isTargetMode = !mapService.isTargetMode;
    notifyListeners();
  }

  void trafficButtonHandler() {
    mapService.isTrafficEnabled = !mapService.isTrafficEnabled;
    notifyListeners();
  }

  void searchButtonHandler() {
    mapService.isSearchMode = !mapService.isSearchMode;
    notifyListeners();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
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

  Future<bool> tryGetPermission() async {
    var value = await loc.Location().requestPermission();
    if (value == loc.PermissionStatus.granted) {
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
}
