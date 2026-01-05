// directions_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving/';

  Future<Map<String, dynamic>?> getRouteDirections(
      LatLng origin, LatLng destination) async {
    final url =
        '$_baseUrl${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
    }
    return null;
  }

  double? parseDistance(Map<String, dynamic>? response) {
    if (response == null ||
        response['routes'] == null ||
        (response['routes'] as List).isEmpty) {
      return null;
    }

    try {
      final routes = response['routes'] as List;
      if (routes.isNotEmpty) {
        final route = routes.first as Map<String, dynamic>;
        final distance = route['distance'];

        if (distance is int) {
          return distance.toDouble();
        } else if (distance is double) {
          return distance;
        }
      }
    } catch (e) {
      debugPrint('Error parsing distance: $e');
    }
    return null;
  }

  // List<LatLng>? parsePolyline(Map<String, dynamic> response) {
  //   try {
  //     final routes = response['routes'] as List;
  //     // debugPrint('Routes: $routes');
  //     if (routes.isEmpty) {
  //       debugPrint('Routes: $routes');

  //       return null;
  //     }

  //     final points = routes[0]['overview_polyline']['points'] as String;
  //     // debugPrint('Routes: $routes');
  //     return decodePolyline(points);
  //   } catch (e) {
  //     return null;
  //   }
  // }

  List<LatLng>? parsePolyline(Map<String, dynamic> response) {
    try {
      final routes = response['routes'] as List;
      debugPrint('Routes: $routes');
      if (routes.isEmpty) {
        debugPrint('empty: $routes');
        return null;
      }

      // Cast routes[0] to Map<String, dynamic>
      final route = routes[0] as Map<String, dynamic>;

      // Check for 'geometry' field (OSRM default) or 'overview_polyline'
      String points;
      if (route.containsKey('geometry')) {
        points = route['geometry'] as String;
      } else if (route.containsKey('overview_polyline')) {
        points = (route['overview_polyline'] as Map<String, dynamic>)['points']
            as String;
      } else {
        debugPrint('No polyline data found in response');
        return null;
      }
      debugPrint('Points: $points');
      return decodePolyline(points);
    } catch (e) {
      debugPrint('Error parsing polyline: $e');
      return null;
    }
  }

  // List<LatLng> decodePolyline(String encoded) {
  //   List<LatLng> poly = [];
  //   int index = 0, len = encoded.length;
  //   int lat = 0, lng = 0;

  //   while (index < len) {
  //     int shift = 0;
  //     int result = 0;

  //     do {
  //       result |= (encoded.codeUnitAt(index) - 63 & 0x1F) << shift;
  //       shift += 5;
  //       index++;
  //     } while (index < len && encoded.codeUnitAt(index - 1) > 31);

  //     int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
  //     lat += dlat;

  //     shift = 0;
  //     result = 0;

  //     do {
  //       result |= (encoded.codeUnitAt(index) - 63 & 0x1F) << shift;
  //       shift += 5;
  //       index++;
  //     } while (index < len && encoded.codeUnitAt(index - 1) > 31);

  //     int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
  //     lng += dlng;

  //     poly.add(LatLng(lat / 1e5, lng / 1e5));
  //   }

  //   return poly;
  // }
  List<LatLng> decodePolyline(String encoded) {
  List<LatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int shift = 0;
    int result = 0;

    // Decode latitude
    do {
      if (index >= len) {
        debugPrint('Incomplete polyline data for latitude at index $index');
        return poly;
      }
      int b = encoded.codeUnitAt(index) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
      index++;
    } while (index < len && (encoded.codeUnitAt(index - 1) - 63) >= 0x20);

    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;

    // Decode longitude
    do {
      if (index >= len) {
        debugPrint('Incomplete polyline data for longitude at index $index');
        return poly;
      }
      int b = encoded.codeUnitAt(index) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
      index++;
    } while (index < len && (encoded.codeUnitAt(index - 1) - 63) >= 0x20);

    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    poly.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return poly;
}
}
