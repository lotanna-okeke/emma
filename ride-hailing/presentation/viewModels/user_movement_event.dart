import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/widgets.dart';

abstract class UserMovementEvent extends Equatable {
  const UserMovementEvent();
  @override
  List<Object?> get props => [];
}

class StartTracking extends UserMovementEvent {}

class StopTracking extends UserMovementEvent {}

class UpdatePosition extends UserMovementEvent {
  const UpdatePosition({
    required this.position,
    required this.speed,
    this.etaMinutes,
    this.accuracy,
    this.distance,
  });

  final LatLng position;
  final double speed;
  final double? etaMinutes;
  final double? accuracy;
  final double? distance;

  @override
  List<Object?> get props => [position, speed, etaMinutes, accuracy, distance];
}

class UpdateDestination extends UserMovementEvent {
  final LatLng destination;
  const UpdateDestination(this.destination);

  @override
  List<Object?> get props => [destination];
}

class ChangeSpeedUnit extends UserMovementEvent {
  final SpeedUnit unit;
  const ChangeSpeedUnit(this.unit);

  @override
  List<Object?> get props => [unit];
}

class AppStateChanged extends UserMovementEvent {
  final AppLifecycleState state;
  const AppStateChanged(this.state);

  @override
  List<Object?> get props => [state];
}

enum SpeedUnit { kmh, mph }
