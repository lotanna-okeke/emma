import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as latlng;

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  DateTime? _lastTime;
  final Distance _distanceCalculator = Distance();
  final List<Position> _positionHistory = [];

  MarkerIcon? _personMarker;
  MarkerIcon? _directionMarker;

  MapBloc() : super(MapInitial()) {
    on<StartTracking>(_onStartTracking);
    on<LoadCustomMarkers>(_onLoadCustomMarkers);
    on<UpdateLocation>(_onUpdateLocation);
  }

  void _onLoadCustomMarkers(
      LoadCustomMarkers event, Emitter<MapState> emit) async {
    final person = MarkerIcon(
      iconWidget: SizedBox(
        width: 80,
        height: 80,
        child: Image.asset(event.iconPath, fit: BoxFit.contain),
      ),
    );

    final direction = MarkerIcon(
      icon: const Icon(Icons.double_arrow, size: 48, color: Colors.blue),
    );

    _personMarker = person;
    _directionMarker = direction;

    emit(MarkerLoaded(personMarker: person, directionMarker: direction));
  }

  void _onStartTracking(StartTracking event, Emitter<MapState> emit) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        bool enabled = await Geolocator.openLocationSettings();
        if (!enabled) {
          emit(MapError("Location services must be enabled"));
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          emit(MapError("Location permissions required"));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(MapError(
            "Location permissions permanently denied. Enable in settings."));
        return;
      }

      // Start position stream with optimal settings
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen((position) {
        // Create new position with timestamp if missing
        final processedPosition = position.timestamp != null
            ? position
            : _createPositionWithTimestamp(position);

        if (processedPosition.accuracy <= 15.0) {
          add(UpdateLocation(
            position: processedPosition,
            destination: event.destination,
          ));
        }
      });

      // Emit initial position
      add(UpdateLocation(
        position: Position(
          latitude: event.currentLocation.latitude,
          longitude: event.currentLocation.longitude,
          timestamp: DateTime.now(),
          accuracy: 1.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 1.0,
          altitudeAccuracy: 1.0,
          headingAccuracy: 1.0,
          isMocked: false,
        ),
        destination: event.destination,
      ));
    } catch (e) {
      emit(MapError("Failed to start tracking: ${e.toString()}"));
    }
  }

  Position _createPositionWithTimestamp(Position position) {
    return Position(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      altitudeAccuracy: position.altitudeAccuracy,
      headingAccuracy: position.headingAccuracy,
      isMocked: position.isMocked,
    );
  }

  void _onUpdateLocation(UpdateLocation event, Emitter<MapState> emit) {
    // Filter out low-accuracy positions
    if (event.position.accuracy > 20.0) {
      return;
    }

    // Calculate speed using both methods
    final deviceSpeed = event.position.speed * 3.6;
    final calculatedSpeed = _calculateManualSpeed(event.position);
    final speedKmh = _getFilteredSpeed(deviceSpeed, calculatedSpeed);

    final remainingDistance = _distanceCalculator.as(
      LengthUnit.Kilometer,
      LatLng(event.position.latitude, event.position.longitude),
      event.destination,
    );

    final etaMinutes =
        speedKmh > 0.5 ? remainingDistance / speedKmh * 60 : null;

    emit(LocationUpdated(
      position: event.position,
      speed: speedKmh,
      etaMinutes: etaMinutes,
      destination: event.destination,
      personMarker: _personMarker,
      directionMarker: _directionMarker,
    ));
  }

  double _calculateManualSpeed(Position newPosition) {
    if (_lastPosition == null || _lastTime == null) {
      _lastPosition = newPosition;
      _lastTime = newPosition.timestamp ?? DateTime.now();
      return 0.0;
    }

    final timeDelta = (newPosition.timestamp ?? DateTime.now())
        .difference(_lastTime!)
        .inSeconds;

    if (timeDelta <= 0) return 0.0;

    final distance = _distanceCalculator.as(
      LengthUnit.Kilometer,
      LatLng(_lastPosition!.latitude, _lastPosition!.longitude),
      LatLng(newPosition.latitude, newPosition.longitude),
    );

    _lastPosition = newPosition;
    _lastTime = newPosition.timestamp ?? DateTime.now();

    return (distance / timeDelta) * 3600; // km/h
  }

  double _getFilteredSpeed(double deviceSpeed, double calculatedSpeed) {
    const double noiseThreshold = 0.3; // km/h
    const double minMovementSpeed = 1.0; // km/h
    const int maxHistory = 5;

    // Add to history
    _positionHistory.add(Position(
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(),
      speed: deviceSpeed / 3.6, // Convert back to m/s
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      isMocked: false,
    ));

    if (_positionHistory.length > maxHistory) {
      _positionHistory.removeAt(0);
    }

    // Use calculated speed when device speed is unreliable
    if (deviceSpeed < noiseThreshold && calculatedSpeed > minMovementSpeed) {
      return calculatedSpeed;
    }

    // Average the last few readings
    if (_positionHistory.length >= 3) {
      final avgSpeed =
          _positionHistory.map((p) => p.speed * 3.6).reduce((a, b) => a + b) /
              _positionHistory.length;

      return avgSpeed > noiseThreshold
          ? double.parse(avgSpeed.toStringAsFixed(1))
          : 0.0;
    }

    return deviceSpeed;
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    _positionHistory.clear();
    return super.close();
  }
}
