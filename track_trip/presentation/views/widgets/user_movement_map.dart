import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../viewModels/map_bloc.dart';

class UserMovementMap extends StatefulWidget {
  final latlng.LatLng currentLocation;
  final latlng.LatLng destination;
  final String iconPath;

  const UserMovementMap({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.iconPath,
  });

  @override
  State<UserMovementMap> createState() => _UserMovementMapState();
}

class _UserMovementMapState extends State<UserMovementMap> {
  
  late MapController mapController;
  final MarkerIcon _defaultPersonMarker = const MarkerIcon(
    icon: Icon(Icons.location_on_outlined, color: Colors.blue),
  );
  final MarkerIcon _defaultDirectionMarker = const MarkerIcon(
    icon: Icon(Icons.person, color: Colors.red),
  );
  final MarkerIcon _destinationMarker = const MarkerIcon(
    icon: Icon(Icons.location_pin, color: Colors.red, size: 48),
  );
  GeoPoint? _destinationPoint;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _destinationPoint = GeoPoint(
      latitude: widget.destination.latitude,
      longitude: widget.destination.longitude,
    );

    mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    // Initialize markers and start tracking after map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MapBloc>();
      bloc.add(LoadCustomMarkers(iconPath: widget.iconPath));
      bloc.add(StartTracking(
        currentLocation: widget.currentLocation,
        destination: widget.destination,
      ));
    });
  }

  Future<void> _addDestinationMarker() async {
    if (!_isMapReady || _destinationPoint == null) return;

    try {
      await mapController.addMarker(
        _destinationPoint!,
        markerIcon: _destinationMarker,
      );
      // Optional: Zoom to show both user and destination
      await mapController.setZoom(zoomLevel: 15);
    } catch (e) {
      debugPrint('Error adding deßstination marker: $e');
    }
  }

  OSMOption _buildOSMOption(
      MarkerIcon? personMarker, MarkerIcon? directionMarker) {
    return OSMOption(
      zoomOption: ZoomOption(
        initZoom: 2,
        minZoomLevel: 2,
        maxZoomLevel: 19,
      ),
      userTrackingOption: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
      userLocationMarker: UserLocationMaker(
        personMarker: personMarker ?? _defaultPersonMarker,
        directionArrowMarker: directionMarker ?? _defaultDirectionMarker,
      ),
      roadConfiguration: const RoadOption(
        roadColor: Colors.blueAccent,
      ),
    );
  }

  void _zoomIn() => mapController.zoomIn();
  void _zoomOut() => mapController.zoomOut();

  @override
  Widget build(BuildContext context) {
    return BlocListener<MapBloc, MapState>(
      listener: (context, state) {
        if (state is MapError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state is MapError) {
            return _buildErrorState(state.message);
          } else if (state is MarkerLoaded) {
            return _buildMapWithMarkers(state);
          } else if (state is LocationUpdated) {
            return _buildTrackingMap(state);
          }
          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _retryInitialization(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Initializing map...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMapWithMarkers(MarkerLoaded state) {
    return OSMFlutter(
      controller: mapController,
      osmOption: _buildOSMOption(state.personMarker, state.directionMarker),
      onMapIsReady: (isReady) {
        if (isReady) {
          setState(() => _isMapReady = true);
          _addDestinationMarker();
        }
      },
    );
  }

  Widget _buildTrackingMap(LocationUpdated state) {
    // Ensure destination marker stays when location updates
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _addDestinationMarker());

    return Stack(
      children: [
        OSMFlutter(
          controller: mapController,
          osmOption: _buildOSMOption(state.personMarker, state.directionMarker),
          onMapIsReady: (isReady) {
            if (isReady && !_isMapReady) {
              setState(() => _isMapReady = true);
              _addDestinationMarker();
            }
          },
        ),

        // Enhanced position info display
        Positioned(
          top: 16,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ETA Display
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatEta(state.etaMinutes),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              // Current Position
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current: ${state.position.latitude.toStringAsFixed(6)}, '
                      '${state.position.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      'Destination: ${state.destination.latitude.toStringAsFixed(6)}, '
                      '${state.destination.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      'Accuracy: ${state.position.accuracy?.toStringAsFixed(1) ?? 'N/A'}m',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Enhanced Speed Display
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: state.speed > 0.5
                  ? Colors.blue.withOpacity(0.8)
                  : Colors.grey.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  state.speed > 0.5
                      ? "${state.speed.toStringAsFixed(1)} km/h"
                      : "0",
                  style: const TextStyle(color: Colors.white),
                ),
                if (state.position.speedAccuracy != null &&
                    state.position.speedAccuracy! > 0)
                  Text(
                    "±${state.position.speedAccuracy!.toStringAsFixed(1)} m/s",
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
              ],
            ),
          ),
        ),

        // Zoom Controls (unchanged)
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoomIn',
                mini: true,
                onPressed: _zoomIn,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'zoomOut',
                mini: true,
                onPressed: _zoomOut,
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _retryInitialization() {
    final bloc = context.read<MapBloc>();
    bloc.add(LoadCustomMarkers(iconPath: widget.iconPath));
    bloc.add(StartTracking(
      currentLocation: widget.currentLocation,
      destination: widget.destination,
    ));
  }

  String _formatEta(double? etaMinutes) {
    if (etaMinutes == null || etaMinutes <= 0) return 'ETA: --';
    const int minutesInHour = 60;
    const int minutesInDay = 1440;
    const int minutesInWeek = minutesInDay * 7;
    const int minutesInMonth = minutesInDay * 30;
    const int minutesInYear = minutesInDay * 365;

    if (etaMinutes < minutesInHour) {
      return "${etaMinutes.toStringAsFixed(0)} min";
    } else if (etaMinutes < minutesInDay) {
      final hours = (etaMinutes / minutesInHour).floor();
      final mins = (etaMinutes % minutesInHour).round();
      return "$hours hr${hours > 1 ? 's' : ''}${mins > 0 ? ' $mins min' : ''}";
    } else if (etaMinutes < minutesInWeek) {
      final days = (etaMinutes / minutesInDay).floor();
      final hours = ((etaMinutes % minutesInDay) / minutesInHour).floor();
      return "$days day${days > 1 ? 's' : ''}${hours > 0 ? ' $hours hr' : ''}";
    } else if (etaMinutes < minutesInMonth) {
      final weeks = (etaMinutes / minutesInWeek).floor();
      final days = ((etaMinutes % minutesInWeek) / minutesInDay).floor();
      return "$weeks week${weeks > 1 ? 's' : ''}${days > 0 ? ' $days day${days > 1 ? 's' : ''}' : ''}";
    } else if (etaMinutes < minutesInYear) {
      final months = (etaMinutes / minutesInMonth).floor();
      final weeks = ((etaMinutes % minutesInMonth) / minutesInWeek).floor();
      return "$months month${months > 1 ? 's' : ''}${weeks > 0 ? ' $weeks week${weeks > 1 ? 's' : ''}' : ''}";
    } else {
      final years = (etaMinutes / minutesInYear).floor();
      final months = ((etaMinutes % minutesInYear) / minutesInMonth).floor();
      return "$years year${years > 1 ? 's' : ''}${months > 0 ? ' $months month${months > 1 ? 's' : ''}' : ''}";
    }
  }
}
