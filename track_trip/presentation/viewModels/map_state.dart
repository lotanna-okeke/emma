part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapTracking extends MapState {}

class LocationUpdated extends MapState {
  final Position position;
  final double speed;
  final double? etaMinutes;
  final LatLng destination;
  final MarkerIcon? personMarker;
  final MarkerIcon? directionMarker;

  const LocationUpdated({
    required this.position,
    required this.speed,
    required this.etaMinutes,
    required this.destination,
    this.personMarker,
    this.directionMarker,
  });

  @override
  List<Object?> get props => [
        position,
        speed,
        etaMinutes ?? 0,
        destination,
        personMarker,
        directionMarker,
      ];
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkerLoaded extends MapState {
  final MarkerIcon personMarker;
  final MarkerIcon directionMarker;

  const MarkerLoaded({
    required this.personMarker,
    required this.directionMarker,
  });

  @override
  List<Object?> get props => [personMarker, directionMarker];
}