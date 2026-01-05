import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/services/directions_service.dart';
import 'user_movement_event.dart';
import 'user_movement_state.dart';

class UserMovementBloc extends Bloc<UserMovementEvent, UserMovementState> {
  UserMovementBloc() : super(TrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<UpdatePosition>(_onUpdatePosition);
    on<UpdateDestination>(_onUpdateDestination);
    on<ChangeSpeedUnit>(_onChangeSpeedUnit);
  }

  final DirectionsService _directionsService = DirectionsService();
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination;

  Future<void> _onStartTracking(
      StartTracking event, Emitter<UserMovementState> emit) async {
    final hasPermission = await _handleLocationPermission(emit);
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) async {
      // Make this async
      final current = LatLng(position.latitude, position.longitude);
      final speed = position.speed;
      final accuracy = position.accuracy;

      double? distance;
      double? etaMinutes;

      if (_destination != null) {
        // Try to get route distance first
        final routeResponse =
            await _directionsService.getRouteDirections(current, _destination!);

        distance = _directionsService.parseDistance(routeResponse);

        // Fallback to direct distance if route not available
        distance ??= Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          _destination!.latitude,
          _destination!.longitude,
        );

        if (speed > 0) {
          etaMinutes = (distance / speed) / 60;
        }
      }

      add(UpdatePosition(
        position: current,
        speed: speed,
        etaMinutes: etaMinutes,
        accuracy: accuracy,
        distance: distance, // Add this line
      ));
    });
  }

  void _onStopTracking(StopTracking event, Emitter<UserMovementState> emit) {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _onUpdatePosition(
      UpdatePosition event, Emitter<UserMovementState> emit) async {
    final current = state is Tracking ? (state as Tracking) : null;
  
    List<LatLng>? routePolyline;
    double? distance;
    double? etaMinutes;
  
    // Only recalculate if destination exists
    if (_destination != null) {
      final routeResponse = await _directionsService.getRouteDirections(event.position, _destination!);
      if (routeResponse!= null) {
        distance = _directionsService.parseDistance(routeResponse);
        routePolyline = _directionsService.parsePolyline(routeResponse);
      }
      // Fallback to direct distance if route not available
      distance ??= Geolocator.distanceBetween(
        event.position.latitude,
        event.position.longitude,
        _destination!.latitude,
        _destination!.longitude,
      );
      routePolyline ??= <LatLng>[];
      if (event.speed > 0) {
        etaMinutes = (distance / event.speed) / 60;
      }
    }
  
    emit(Tracking(
      currentLocation: event.position,
      speed: event.speed,
      etaMinutes: etaMinutes ?? event.etaMinutes,
      accuracy: event.accuracy,
      speedUnit: current?.speedUnit ?? SpeedUnit.kmh,
      distance: distance ?? event.distance,
      destination: current?.destination,
      routePolyline: routePolyline ?? current?.routePolyline,
    ));
  }

  //Los Angeles

  Future<void> _onUpdateDestination(
      UpdateDestination event, Emitter<UserMovementState> emit) async {
    // Always update the destination field
    _destination = event.destination;

    if (state is Tracking) {
      final current = state as Tracking;

      // First emit state with new destination and null distance/eta
      emit(current.copyWith(
        destination: event.destination,
        distance: null,
        etaMinutes: null,
        routePolyline: null,
      ));

      if (current.currentLocation != null) {
        try {
          final routeResponse = await _directionsService.getRouteDirections(
              current.currentLocation!, event.destination);
          debugPrint('Route Response $routeResponse');

          double? distance;
          List<LatLng>? routePoints;

          if (routeResponse != null) {
            distance = _directionsService.parseDistance(routeResponse);

            routePoints = _directionsService.parsePolyline(routeResponse);
            debugPrint('Route Points $routePoints');
          }

          distance ??= Geolocator.distanceBetween(
            current.currentLocation!.latitude,
            current.currentLocation!.longitude,
            event.destination.latitude,
            event.destination.longitude,
          );

          routePoints ??= <LatLng>[];

          double? etaMinutes;
          if (current.speed > 0) {
            etaMinutes = (distance / current.speed) / 60;
          }

          emit(current.copyWith(
            destination: event.destination,
            distance: distance,
            etaMinutes: etaMinutes,
            routePolyline: routePoints,
          ));
        } catch (e) {
          emit(current.copyWith(
            destination: event.destination,
            distance: null,
            etaMinutes: null,
            routePolyline: null, // Add this line
          ));
        }
      }
    } else {
      // Handle case when we get destination before tracking starts
      emit(Tracking(
        currentLocation: null,
        destination: event.destination,
        speed: 0.0,
      ));
    }
  }

  void _onChangeSpeedUnit(
      ChangeSpeedUnit event, Emitter<UserMovementState> emit) {
    if (state is Tracking) {
      final current = (state as Tracking);
      emit(current.copyWith(speedUnit: event.unit));
    }
  }

  Future<bool> _handleLocationPermission(
      Emitter<UserMovementState> emit) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(const TrackingError('Location services are disabled.'));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(const TrackingError('Location permission denied.'));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      emit(const TrackingError('Location permissions are permanently denied.'));
      return false;
    }

    return true;
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}
