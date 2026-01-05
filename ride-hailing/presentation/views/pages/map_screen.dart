import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../viewModels/user_movement_bloc.dart';
import '../../viewModels/user_movement_event.dart';
import '../widgets/user_movement_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BitmapDescriptor? _customIcon;
  final LatLng initialDestination = const LatLng(6.465422, 3.406448);
  final speedUnit = SpeedUnit.mph; // Set the initial speed unit to km/

  @override
  void initState() {
    super.initState();
    _loadCustomIcon();
  }

  Future<void> _loadCustomIcon() async {
    final icon =
        await AssetMapBitmap('assets/images/car.png', width: 48, height: 48);
    setState(() {
      _customIcon = icon;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserMovementBloc>(
      create: (BuildContext context) {
        final bloc = UserMovementBloc();
        // Dispatch initial events
        bloc.add(UpdateDestination(initialDestination));
        bloc.add(ChangeSpeedUnit(speedUnit));
        bloc.add(StartTracking()); // Ensure tracking starts immediately
        return bloc;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Movement Map with Bloc'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Map Controls'),
                    content: const Text(
                      '• Tap anywhere on the map to set destination\n'
                      '• Tap the speed display to toggle between km/h and mph\n'
                      '• Tap your location marker for detailed info',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _customIcon == null
            ? const Center(child: CircularProgressIndicator())
            : UserMovementMap(
                initialDestination: initialDestination,
                customIcon: _customIcon!,
                initialSpeedUnit: speedUnit,
              ),
      ),
    );
  }
}