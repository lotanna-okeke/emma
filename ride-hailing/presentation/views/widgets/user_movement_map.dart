import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_interface/src/types/geo_point.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../../core/constants/colors.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../../../track_trip/data/services/api.dart';
import '../../viewModels/user_movement_bloc.dart';
import '../../viewModels/user_movement_event.dart';
import '../../viewModels/user_movement_state.dart';

class UserMovementMap extends StatefulWidget {
  final BitmapDescriptor customIcon;
  final LatLng initialDestination;
  final double zoomLevel;
  final MapType mapType;
  final SpeedUnit initialSpeedUnit;

  const UserMovementMap({
    Key? key,
    required this.customIcon,
    required this.initialDestination,
    this.zoomLevel = 16.0,
    this.mapType = MapType.normal,
    this.initialSpeedUnit = SpeedUnit.kmh,
  }) : super(key: key);

  @override
  _UserMovementMapState createState() => _UserMovementMapState();
}

class _UserMovementMapState extends State<UserMovementMap> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  // LatLng? _destination;
  Timer? _throttleTimer;
  late UserMovementBloc _bloc;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _mapIsOnUser = false;
  bool _justStarted = true;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<UserMovementBloc>();
    // Remove redundant event dispatching since it's handled in MapScreen
    _bloc.add(StartTracking());
  }

  @override
  void dispose() {
    _bloc.add(StopTracking());
    _mapController?.dispose();
    _searchController.dispose();
    _throttleTimer?.cancel();
    super.dispose();
  }

  Future<void> _onMoveCamera(LatLng position, bool onUser) async {
    try {
      final GoogleMapController? controller = _mapController;
      if (controller != null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: position,
              zoom: 17,
            ),
          ),
        );
        setState(() {
          _mapIsOnUser = !_mapIsOnUser;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar(
                type: SnackBarType.fail,
                message:
                    'Failed to navigate to ${onUser ? 'destination' : 'current location'}: $e')
            .show(context);
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) async {
    _bloc.add(UpdateDestination(position));
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    _onMoveCamera(position, true);
  }

  Future<void> _searchAndSetDestination() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      const CustomSnackBar(
        type: SnackBarType.information,
        message: 'Please enter a destination address.',
      ).show(context);
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final LatLng coordinates = await nominatimSearch(query);
      debugPrint(
          "Search result: ${coordinates.latitude}, ${coordinates.longitude}");
      if (mounted) {
        _onMapTap(coordinates); // This sets the destination marker
      }
    } catch (e) {
      debugPrint("Search found: $e");
      final bool noInternet = e.toString().contains('No Internet');
      final String message = e.toString().contains('No search results')
          ? 'No results found.'
          : 'Error: $e';
      CustomSnackBar(
              type: noInternet ? SnackBarType.information : SnackBarType.fail,
              message: noInternet
                  ? 'Please check your internet connection'
                  : message)
          .show(context);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _throttleUpdate(void Function() callback) {
    if (_throttleTimer?.isActive ?? false) return;
    callback();
    _throttleTimer = Timer(const Duration(milliseconds: 500), () {});
  }

  String _formatETA(double? minutes) {
    if (minutes == null || minutes < 0) {
      return 'Calculating ETA...';
    }
    final duration = Duration(minutes: minutes.round());
    if (duration.inDays > 0) {
      return 'ETA: ${duration.inDays}d ${duration.inHours % 24}h';
    }
    if (duration.inHours > 0) {
      return 'ETA: ${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return 'ETA: ${duration.inMinutes}m';
  }

  Future<void> _goToDestination() async {
    final state = _bloc.state;
    debugPrint('State: ${state is Tracking}');
    debugPrint(
        'Destination: ${(state is Tracking) ? state.destination : 'Not null'}');
    if (state is! Tracking || state.destination == null) {
      if (mounted) {
        const CustomSnackBar(
                type: SnackBarType.information,
                message: 'No destination set yet')
            .show(context);
      }
      if (state is Tracking) {
        debugPrint("It's tracking");
      }
      return;
    }

    _onMoveCamera(state.destination!, true);
  }
  // Future<void> _goToDestination() async {
  //   final state = _bloc.state;
  //   debugPrint('GoToDestination - State: ${state.runtimeType}, Destination: ${(state is Tracking) ? state.destination : 'null'}');

  //   // Use initialDestination as fallback if state destination is null
  //   final destination = (state is Tracking && state.destination != null)
  //       ? state.destination
  //       : widget.initialDestination;

  //   if (destination == null) {
  //     debugPrint('No destination available');
  //     if (mounted) {
  //       const CustomSnackBar(
  //         type: SnackBarType.information,
  //         message: 'No destination set yet',
  //       ).show(context);
  //     }
  //     return;
  //   }

  //   try {
  //     await _onMoveCamera(destination, true);
  //     debugPrint('Moved camera to destination: $destination');
  //   } catch (e) {
  //     debugPrint('Error moving to destination: $e');
  //     if (mounted) {
  //       CustomSnackBar(
  //         type: SnackBarType.fail,
  //         message: 'Failed to navigate to destination: $e',
  //       ).show(context);
  //     }
  //   }
  // }

  void _toggleSpeedUnit() {
    final current = _bloc.state;
    final newUnit = (current is Tracking && current.speedUnit == SpeedUnit.kmh)
        ? SpeedUnit.mph
        : SpeedUnit.kmh;
    _bloc.add(ChangeSpeedUnit(newUnit));
  }

  // Add this method to _UserMovementMapState
  void _simulateMovement(double latChange, double lngChange) {
    if (_currentLocation == null) return;

    final newLocation = LatLng(
      _currentLocation!.latitude + latChange,
      _currentLocation!.longitude + lngChange,
    );

    // Simulate a speed of 5 m/s (18 km/h)
    _bloc.add(UpdatePosition(
      position: newLocation,
      speed: 5.0,
      accuracy: 5.0,
    ));

    // Move camera to new location
    _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
  }

  Set<Polyline> _polylines = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserMovementBloc, UserMovementState>(
      builder: (context, state) {
        LatLng? destination = (state is Tracking && state.destination != null)
            ? state.destination
            : widget.initialDestination;
        if (state is Tracking) {
          // final destination = state.destination ?? widget.initialDestination;
          _currentLocation = state.currentLocation;

          // Update polylines if route is available
          _polylines = state.routePolyline != null
              ? {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: state.routePolyline!,
                    color: StragColor.primary,
                    width: 5,
                  ),
                }
              : <Polyline>{};

          debugPrint(state.routePolyline != null
              ? 'Route available'
              : 'No route available');

          final etaText = _formatETA(state.etaMinutes);

          return (_currentLocation == null)
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation ?? widget.initialDestination,
                        zoom: widget.zoomLevel,
                      ),
                      mapType: widget.mapType,
                      myLocationEnabled: true,
                      polylines: _polylines, // Add polylines to the map
                      myLocationButtonEnabled: false,
                      markers: {
                        if (_currentLocation != null)
                          Marker(
                            markerId: const MarkerId('user'),
                            position: _currentLocation!,
                            icon: widget.customIcon,
                            infoWindow: InfoWindow(
                              title: 'Your Location',
                              snippet:
                                  'Speed: ${state.displaySpeed.toStringAsFixed(1)} ${state.speedUnitLabel}\n'
                                  'Accuracy: ±${state.accuracy?.toStringAsFixed(1) ?? 'N/A'}m',
                            ),
                            onTap: () {
                              _mapController?.showMarkerInfoWindow(
                                  const MarkerId('user'));
                            },
                          ),
                        // Always show destination marker (either from state or initial)
                        Marker(
                          markerId: const MarkerId('destination'),
                          position: destination!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed),
                          infoWindow: InfoWindow(
                            title: 'Destination',
                            snippet: state is Tracking
                                ? state.distanceLabel
                                : 'Initial destination',
                          ),
                          onTap: () {
                            if (state is Tracking) {
                              _bloc.add(UpdateDestination(destination));
                            }
                            _mapController?.showMarkerInfoWindow(
                                const MarkerId('destination'));
                          },
                        ),
                      },
                      onTap: _onMapTap,
                    ),

                    // Floating search bar
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for a location',
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: _isSearching
                                          ? null
                                          : _searchAndSetDestination, // Call search on button press
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                            ),
                            onSubmitted: (value) {
                              _searchAndSetDestination();
                            },
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 80,
                      left: 16,
                      // right: 16,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: Text(etaText),
                          ),
                          GestureDetector(
                            onTap: _toggleSpeedUnit,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 6),
                                ],
                              ),
                              child: Text(
                                  'Speed: ${state.displaySpeed.toStringAsFixed(1)} ${state.speedUnitLabel}'),
                            ),
                          ),
                        ],
                      ),
                      // ),
                    ),

                    // Go to destination/current location button
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: ElevatedButton(
                        onPressed: _mapIsOnUser
                            ? _goToDestination
                            : () {
                                _onMoveCamera(_currentLocation!, false);
                              },
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(
                                Icons.location_on_sharp,
                                size: 20,
                              ),
                              SizedBox(width: 5),
                              Text(
                                _mapIsOnUser
                                    ? 'Go the Destination'
                                    : 'Re-center Map',
                                style: TextStyle(fontSize: 14),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Add this to the Stack children in UserMovementMap's build method
                    if (kDebugMode)
                      Positioned(
                        bottom: 150,
                        right: 16,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'simulate_north',
                              onPressed: () => _simulateMovement(0.0001, 0),
                              child: const Icon(Icons.arrow_upward),
                            ),
                            Row(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'simulate_west',
                                  onPressed: () =>
                                      _simulateMovement(0, -0.0001),
                                  child: const Icon(Icons.arrow_back),
                                ),
                                const SizedBox(width: 8),
                                FloatingActionButton.small(
                                  heroTag: 'simulate_east',
                                  onPressed: () => _simulateMovement(0, 0.0001),
                                  child: const Icon(Icons.arrow_forward),
                                ),
                              ],
                            ),
                            FloatingActionButton.small(
                              heroTag: 'simulate_south',
                              onPressed: () => _simulateMovement(-0.0001, 0),
                              child: const Icon(Icons.arrow_downward),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
        } else if (state is TrackingError) {
          return Center(
            child: Text('Error: ${state.errorMessage}'),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
