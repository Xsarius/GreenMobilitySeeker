import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'app_settings.dart';

Future<List<double>?> getUserLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Position position = await Geolocator.getCurrentPosition();
      return [position.latitude, position.longitude];
    } else {
      throw Exception("Location permission not granted");
    }
  } catch (e) {
    Fluttertoast.showToast(msg: "Error getting user's location: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> sendPostRequest(
    String url, Map<String, dynamic> data) async {
  Map<String, String> headers = {"Content-Type": "application/json"};

  try {
    final response = await http.post(Uri.parse(url),
        body: jsonEncode(data), headers: headers);

    if (response.statusCode == 200) {
      print("Request successful:");
      Map<String, dynamic> responseData = json.decode(response.body);
      print(responseData);
      return responseData;
    } else {
      print("Request failed with status code: ${response.statusCode}");
      print(response.body);
      return null;
    }
  } catch (e) {
    Fluttertoast.showToast(msg: "Error in request: $e");
    return null;
  }
}

Future<Map<String, dynamic>?> sendGetRequest(String url) async {
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print("GET request successful:");
      Map<String, dynamic> responseData = json.decode(response.body);
      print(responseData);
      return responseData;
    } else {
      print("GET request failed with status code: ${response.statusCode}");
      print(response.body);
      return null;
    }
  } catch (e) {
    Fluttertoast.showToast(msg: "Error in GET request: $e");
    return null;
  }
}

Future<List<Map<String, dynamic>>> getCarList() async {
  List<double>? userLocation = await getUserLocation();

  if (userLocation != null) {
    print("User's accurate current location: $userLocation");

    // Prepare the request body with the user's accurate location
    Map<String, dynamic> body = {
      "query":
          "query (\$lat: Float!, \$lng: Float!) {\n  vehicles(lat:   \$lat, lng: \$lng) {\n\t\tpublicId\n battery \n lng \n lat}\n}",
      "variables": {
        "lat": userLocation[0],
        "lng": userLocation[1],
      }
    };

    String baseUrl = "https://flow-api.fluctuo.com/v1";
    String carToken = AppSettingsProvider.getAppSettings().carToken;
    String url = '$baseUrl?access_token=$carToken';

    Map<String, dynamic>? responseData = await sendPostRequest(url, body);

    if (responseData!.containsKey("data") &&
        responseData["data"].containsKey("vehicles") &&
        responseData["data"]["vehicles"] is List) {
      List<dynamic> vehicles = responseData["data"]["vehicles"];

      vehicles =
          vehicles.where((vehicle) => vehicle['battery'] <= 60).toList();

      vehicles.sort((a, b) => a['battery'].compareTo(b['battery']));

      for (var vehicle in vehicles) {
        double distance = calculateDistanceToUser(
          userLocation[0],
          userLocation[1],
          vehicle['lat'],
          vehicle['lng'],
        );
        vehicle['distanceToUser'] = distance;

        if (vehicle['battery'] < 20) {
          vehicle['net_gain'] = 20.0;
        } else if (vehicle['battery'] < 40) {
          vehicle['net_gain'] = 15.0;
        } else if (vehicle['battery'] < 60) {
          vehicle['net_gain'] = 10.0;
        } else {
          vehicle['net_gain'] = 0.0;
        }
      }

      return List<Map<String, dynamic>>.from(vehicles);
    } else {
      return [];
    }
  } else {
      return [];
  }
}

Future<List<Map<String, dynamic>>> getZonesList() async {
  List<double>? userLocation = await getUserLocation();

  if (userLocation != null) {
    print("User's accurate current location: $userLocation");

    // Prepare the request body with the user's accurate location
    Map<String, dynamic> body = {
      "query":
          "query (\$lat: Float!, \$lng: Float!, \$radius: Int, \$providers: [String]) {\n zones (lat: \$lat, lng: \$lng, radius: \$radius, providers: \$providers) {\n\t\t id \n provider{ name } \n name \n geojson}\n}",
      "variables": {
        "lat": userLocation[0],
        "lng": userLocation[1],
        "providers": ["greenmobility"],
        "radius": 1000
      }
    };

    String baseUrl = "https://flow-api.fluctuo.com/v1";
    String carToken = AppSettingsProvider.getAppSettings().carToken;
    String url = '$baseUrl?access_token=$carToken';

    Map<String, dynamic>? responseData = await sendPostRequest(url, body);
    List<Map<String, dynamic>> simplifiedResults = [];

    if (responseData!.containsKey("data") &&
        responseData["data"].containsKey("zones") &&
        responseData["data"]["zones"] is List) {
      List<dynamic> zones = responseData["data"]["zones"];

      for (var zone in zones) {
        Map<String, dynamic> simplifiedResult = {
          'name': zone['name'],
          'coordinates': zone['geojson']['coordinates'][0]
        };

        simplifiedResults.add(simplifiedResult);
      }

      return simplifiedResults;
    } else {
      return [];
    }
  } else {
    return [];
  }
}

Future<List<Map<String, dynamic>>> getChargersList() async {
  String baseUrl = "https://api.tomtom.com/search/2/nearbySearch/.json";
  String chToken = AppSettingsProvider.getAppSettings().chToken;

  try {
    List<double>? userLocation = await getUserLocation();
    String url =
        '$baseUrl?key=$chToken&categorySet=7309&radius=500&lat=${userLocation?[0]}&lon=${userLocation?[1]}&maxPowerKW=43';

    Map<String, dynamic>? responseData = await sendGetRequest(url);

    if (responseData != null && responseData.containsKey("results")) {
      List<dynamic> results = responseData['results'];
      List<Map<String, dynamic>> simplifiedResults = [];

      for (var result in results) {
        Map<String, dynamic> simplifiedResult = {
          'dist_to_usr': result['dist'],
          'poi': {'name': result['poi']['name'], 'url': result['poi']['url']},
          'address': {
            'streetNumber': result['address']['streetNumber'],
            'streetName': result['address']['streetName'],
            'localName': result['address']['localName'],
            'postalCode': result['address']['postalCode'],
            'freeformAddress': result['address']['freeformAddress']
          },
          'position': {
            'lat': result['position']['lat'],
            'lon': result['position']['lon']
          },
          'chargingPark': {
            'dataSources': result['dataSources'] ??
                {
                  'chargingAvailability': {'id': "0"}
                }
          }
        };
        simplifiedResults.add(simplifiedResult);
      }
      return simplifiedResults;
    } else {
      throw Exception('Invalid response format');
    }
  } catch (error) {
    throw Exception('Error: $error');
  }
}

Future<bool> checkChargerAvailability(Map<String, dynamic> charger) async {
  String baseUrl = "https://api.tomtom.com/search/2/chargingAvailability.json";
  String chToken = AppSettingsProvider.getAppSettings().chToken;
  String chAvToken = charger['chargingPark']['dataSources']
          ['chargingAvailability']['id']
      .toString();

  if (chAvToken == "0") {
    return false;
  }

  String url = '$baseUrl?key=$chToken&chargingAvailability=$chAvToken';

  try {
    Map<String, dynamic>? responseData = await sendGetRequest(url);

    if (responseData != null && responseData.containsKey("connectors")) {
      int result =
          responseData['connectors'][0]['availability']['current']['available'];

      if (result > 0) {
        return true;
      } else {
        return false;
      }
    } else {
      throw Exception('Invalid response format');
    }
  } catch (error) {
    throw Exception('Error: $error');
  }
}

Future<List<Map<String, dynamic>>> getDistToChargers(
    List<Map<String, dynamic>> cars,
    List<Map<String, dynamic>> chargers) async {
  List<Map<String, dynamic>> carsWithDistToChargers = [];

  for (var car in cars) {
    double carLat = car['lat'];
    double carLng = car['lng'];
    double minDistance = double.infinity;
    String chargerAddr = "unknown";
    Map<String, dynamic>? nearestCharger;

    for (var charger in chargers) {
      double chargerLat = charger['position']['lat'];
      double chargerLng = charger['position']['lon'];

      double distance =
          Geolocator.distanceBetween(carLat, carLng, chargerLat, chargerLng);

      bool available = await checkChargerAvailability(charger);
      if (available && distance < minDistance) {
        minDistance = distance;
        nearestCharger = charger;
        chargerAddr = charger['address']['freeformAddress'];
      }
    }

    if (nearestCharger != null) {
      car['dist_to_charg'] = minDistance;
      car['char_addr'] = chargerAddr;
      carsWithDistToChargers.add(car);
    }
  }

  return carsWithDistToChargers;
}

List<Map<String, dynamic>> filterChargersInsideZones(
    List<Map<String, dynamic>> chargers, List<Map<String, dynamic>> zones) {
  List<Map<String, dynamic>> chargersInsideZones = [];

  for (var charger in chargers) {
    double chargerLat = charger['position']['lat'];
    double chargerLon = charger['position']['lon'];

    bool insideZone = false;
    for (var zone in zones) {
      List<dynamic> coordinates = zone['coordinates'];
      if (_pointInPolygon(chargerLat, chargerLon, coordinates)) {
        insideZone = true;
        break;
      }
    }

    if (insideZone) {
      chargersInsideZones.add(charger);
    }
  }

  return chargersInsideZones;
}

List<Map<String, dynamic>> estNetGain(List<Map<String, dynamic>> cars) {
  for (var car in cars) {
    double netGain = car['net_gain']; // time in min

    // Est. time needed to drive to charger
    netGain -= car['dist_to_charg'] / 100 * 10 / 60 ; 

    // Est. connecting car to charge
    netGain -= 1;

    car['net_gain'] = netGain.floorToDouble();
  }

  return cars;
}

bool _pointInPolygon(double lat, double lng, List<dynamic> polygon) {
  bool isInside = false;
  int i, j = polygon.length - 1;
  for (i = 0; i < polygon.length; i++) {
    double polyLat = polygon[i][1].toDouble();
    double polyLng = polygon[i][0].toDouble();
    double prevLat = polygon[j][1].toDouble();
    double prevLng = polygon[j][0].toDouble();

    if ((polyLng < lng && prevLng >= lng || prevLng < lng && polyLng >= lng) &&
        (polyLat + (lng - polyLng) / (prevLng - polyLng) * (prevLat - polyLat) <
            lat)) {
      isInside = !isInside;
    }
    j = i;
  }
  return isInside;
}

double calculateDistanceToUser(
    double userLat, double userLng, double carLat, double carLng) {
  return Geolocator.distanceBetween(userLat, userLng, carLat, carLng);
}
