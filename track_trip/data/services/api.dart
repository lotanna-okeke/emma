import 'dart:async';
import 'dart:io';

import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<GeoPoint> addressToGeoPoint(String address) async {
  try {
    final locations = await locationFromAddress(address);
    if (locations.isEmpty) {
      throw Exception('No locations found for: $address');
    }

    final loc = locations.first;
    print('Found location: ${loc.latitude}, ${loc.longitude}');

    return GeoPoint(latitude: loc.latitude, longitude: loc.longitude);
  } catch (e) {
    print('Geocoding failed: $e');
    rethrow;
  }
}

Future<LatLng> nominatimSearch(String address) async {
  try {
    final Uri url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'YourAppName/1.0 (your@email.com)',
      },
    ).timeout(const Duration(seconds: 10)); // Add a timeout
    if (response.statusCode == 200) {
      //print(response.body);
      final decoded = json.decode(response.body);

      // Ensure it's a list
      if (decoded is List && decoded.isNotEmpty) {
        final firstResult = decoded[0];
        final lat = double.parse(firstResult['lat'].toString());
        final lon = double.parse(firstResult['lon'].toString());
        return LatLng(lat, lon);
      } else {
        throw Exception('No search results found.');
      }
    } else {
      throw Exception('Nominatim API error: ${response.statusCode}');
    }
  } on SocketException catch (_) {
    throw 'No Internet';
  } on TimeoutException catch (_) {
    throw 'No Internet';
  } catch (e) {
    // Catch other types of exceptions
    throw Exception('Error: $e');
  }
}
