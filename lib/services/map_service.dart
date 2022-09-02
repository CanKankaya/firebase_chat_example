import 'package:location/location.dart' as loc;
import 'dart:math';

final mapService = MapService();

//TODO: Check conditions below;
//Permission not asked, location disabled
//Permission denied already, location disabled
//Permission granted, location enabled (works fine)
//Permission granted, location disabled

class MapService {
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
}
