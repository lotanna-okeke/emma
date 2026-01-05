import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'user_movement_event.dart';

abstract class UserMovementState extends Equatable {
  const UserMovementState();
  @override
  List<Object?> get props => [];
}

class TrackingInitial extends UserMovementState {}

class Tracking extends UserMovementState {
  const Tracking({
    required this.currentLocation,
    this.speed = 0.0,
    this.etaMinutes,
    this.accuracy,
    this.speedUnit = SpeedUnit.kmh,
    this.distance,
    this.destination,
    this.routePolyline,  // Added routePolyline parameter
  });

  final LatLng? currentLocation;
  final LatLng? destination;
  final double speed; // m/s
  final double? etaMinutes;
  final double? accuracy;
  final SpeedUnit speedUnit;
  final double? distance;
  final List<LatLng>? routePolyline;  // Added routePolyline field

  // Restored getters
  double get displaySpeed =>
      speedUnit == SpeedUnit.kmh ? speed * 3.6 : speed * 2.23694;

  String get speedUnitLabel => speedUnit == SpeedUnit.kmh ? 'km/h' : 'mph';

  String get distanceLabel {
    if (distance == null) return 'Calculating route...';
    return distance! < 1000
        ? '${distance!.toStringAsFixed(0)} meters'
        : '${(distance! / 1000).toStringAsFixed(1)} km';
  }

  Tracking copyWith({
    LatLng? currentLocation,
    LatLng? destination,
    double? speed,
    double? etaMinutes,
    double? accuracy,
    SpeedUnit? speedUnit,
    double? distance,
    List<LatLng>? routePolyline,  // Added to copyWith
  }) {
    return Tracking(
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      speed: speed ?? this.speed,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      accuracy: accuracy ?? this.accuracy,
      speedUnit: speedUnit ?? this.speedUnit,
      distance: distance ?? this.distance,
      routePolyline: routePolyline ?? this.routePolyline,  // Added to constructor
    );
  }

  @override
  List<Object?> get props => [
        currentLocation,
        destination,
        speed,
        etaMinutes,
        accuracy,
        speedUnit,
        distance,
        routePolyline,  // Added to props
      ];
}

class TrackingError extends UserMovementState {
  final String errorMessage;
  const TrackingError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
