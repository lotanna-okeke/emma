part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class StartTracking extends MapEvent {
  final latlng.LatLng destination;
  final latlng.LatLng currentLocation;

  const StartTracking(
      {required this.destination, required this.currentLocation});
}

class UpdateLocation extends MapEvent {
  final Position position;
  final LatLng destination;

  const UpdateLocation({required this.position, required this.destination});

  @override
  List<Object?> get props => [position, destination];
}

class LoadCustomMarkers extends MapEvent {
  final String iconPath;

  const LoadCustomMarkers({required this.iconPath});

  @override
  List<Object?> get props => [iconPath];
}

