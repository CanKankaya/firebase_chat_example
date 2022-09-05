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
  var isSearchMode = false;
  var spamClick = true;
  var spamCheck = false;
  var selectedIndex = 1;
  var selectedTravelMode = TravelMode.driving;

  final GooglePlace googlePlace = GooglePlace(googleMapsApiKey);
  List<AutocompletePrediction> predictions = [];

  late LatLng centerScreen;
  late LatLng markerLocation;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  double totalDistance = 0;

  @override
  Widget build(BuildContext context) {
    if (isPageLoading) {
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
              CustomIconButton(
                iconSize: 32,
                icon: AnimatedIcons.search_ellipsis,
                buttonFon: _searchButtonHandler,
              ),
            ],
          ),
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
                onTap: null,
                onLongPress: _mapOnLongPressHandler,
                onCameraMove: null,
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
                  child: _buildHeadWidget(context),
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
    centerScreen = const LatLng(40.9878681, 29.0367217);
    markerLocation = const LatLng(40.9878681, 29.0367217);
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

          centerScreen = LatLng(value.latitude ?? 0, value.longitude ?? 0);
          SchedulerBinding.instance.addPostFrameCallback((_) {
            deviceWidth = MediaQuery.of(context).size.width;
            deviceHeight = MediaQuery.of(context).size.height;
            screenWidth = deviceWidth * MediaQuery.of(context).devicePixelRatio;
            screenHeight = deviceHeight * MediaQuery.of(context).devicePixelRatio;
            middleX = (screenWidth / 2).round();
            middleY = ((screenHeight / 2) - 120).round();
            setState(() {
              isPageLoading = false;
            });
          });
        });
      } else {
        //
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
    markers.clear();
    polylineCoordinates.clear();
    polylines.clear();
    totalDistance = 0;
    mapController.dispose();

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

  void _onSelect(int index) {
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
      totalDistance += mapService.calculateDistance(
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

    var markerIdVal = mapService.myWayToGenerateId();
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

  void _mapButtonHandler() async {
    if (isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    isTargetMode = false;
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

  void _navigationButtonHandler() async {
    if (isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    setState(() {
      isTargetMode = false;
    });

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

  void _deleteButtonHandler() async {
    setState(() {
      markers.clear();
      polylineCoordinates.clear();
      polylines.clear();
      Future.delayed(const Duration(milliseconds: 500)).then(
        (_) => totalDistance = 0,
      );
    });
  }

  void _targetModeButtonHandler() {
    if (isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }

    setState(() {
      isTargetMode = !isTargetMode;
    });
  }

  void _trafficButtonHandler() {
    setState(() {
      isTrafficEnabled = !isTrafficEnabled;
    });
  }

  void _searchButtonHandler() {
    setState(() {
      isSearchMode = !isSearchMode;
    });
  }

  void _mapOnLongPressHandler(LatLng latLng) {
    if (isSearchMode) {
      mapService.simulateClickFunction(
        clickPosition: Offset(deviceWidth - 25, 50),
      );
    }
    markerLocation = latLng;
    _addMarker(latLng);
  }

  void _autoCompleteSearch(String value) async {
    if (spamCheck == false) {
      var result = await googlePlace.autocomplete.get(value);
      if (result != null && result.predictions != null && mounted) {
        setState(() {
          predictions = result.predictions as List<AutocompletePrediction>;
        });
      }
      spamCheck = true;
      Future.delayed(
        const Duration(seconds: 2),
        () async {
          spamCheck = false;
          var result = await googlePlace.autocomplete.get(value);
          if (result != null && result.predictions != null && mounted) {
            setState(() {
              predictions = result.predictions as List<AutocompletePrediction>;
            });
          }
        },
      );
    }
  }

  Widget _buildHeadWidget(BuildContext context) {
    return ClipRRect(
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
                                _onSelect(0);
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
                                _onSelect(1);
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
                                _onSelect(2);
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
                                _onSelect(3);
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
    );
  }

  Widget _buildExpandableFab() {
    return ExpandableFab(
      alignment: Alignment.bottomLeft,
      distance: 140.0,
      smallDistance: 80.0,
      children: [
        ActionButton(
          isSmall: true,
          onPressed: _deleteButtonHandler,
          backgroundColor: Colors.black,
          icon: Icon(
            Icons.delete,
            color: markers.isNotEmpty ? Colors.amber : Colors.grey,
          ),
        ),
        ActionButton(
          onPressed: _navigationButtonHandler,
          backgroundColor: Colors.black,
          icon: Icon(
            Icons.navigation,
            color: polylines.isNotEmpty ? Colors.amber : Colors.grey,
          ),
        ),
        ActionButton(
          onPressed: _mapButtonHandler,
          backgroundColor: Colors.black,
          icon: isFindingRoute
              ? const SimplerCustomLoader()
              : Icon(
                  Icons.map,
                  color: markers.isNotEmpty ? Colors.amber : Colors.grey,
                ),
        ),
        ActionButton(
          onPressed: _trafficButtonHandler,
          backgroundColor: isTrafficEnabled ? Colors.blue : Colors.black,
          icon: Icon(
            Icons.traffic,
            color: isTrafficEnabled ? Colors.black : Colors.amber,
          ),
        ),
        ActionButton(
          onPressed: _targetModeButtonHandler,
          backgroundColor: isTargetMode ? Colors.blue : Colors.black,
          icon: Icon(
            Icons.control_point,
            color: isTargetMode ? Colors.black : Colors.amber,
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
    );
  }

  Widget _buildSearchSheet() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
        color: isSearchMode ? Theme.of(context).secondaryHeaderColor : Colors.transparent,
      ),
      height: isSearchMode ? 250 : 0,
      width: deviceWidth,
      child: Column(
        children: [
          if (isSearchMode)
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
                    if (predictions.isNotEmpty && mounted) {
                      setState(() {
                        predictions = [];
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
                itemCount: predictions.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    leading: Icon(
                      Icons.location_city,
                      color: isSearchMode ? Colors.white : Colors.transparent,
                    ),
                    title: Text(
                      predictions[i].description ?? 'No Description',
                      style: TextStyle(
                        color: isSearchMode ? null : Colors.transparent,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.pin_drop,
                        color: isSearchMode ? Colors.amber : Colors.transparent,
                      ),
                      onPressed: () async {},
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaceDetailScreen(
                            placeId: predictions[i].placeId ?? '',
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
    );
  }
}
