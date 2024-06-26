

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import 'package:mapapp/const.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();

  // ignore: constant_identifier_names
  static const LatLng _Google = LatLng(37.3223, -122.0848);
  // ignore: constant_identifier_names
  static const LatLng _ApplePark = LatLng(37.3346, -122.0090);

  LatLng? _currentPosition;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLocationUpdates().then(
      (_) => {
        getPolyLinePoints().then((coordinates) => {
              GeneratePolylinesFromPoints(coordinates),
            }),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(
              child: Text("Loading..."),
            )
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _Google,
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("Current Location"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _currentPosition!,
                ),
                const Marker(
                  markerId: MarkerId("Source Location"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _Google,
                ),
                const Marker(
                  markerId: MarkerId("Destination Location"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _ApplePark,
                ),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          print("current Position$_currentPosition");
        });
      }
    });
  }

  Future<List<LatLng>> getPolyLinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Google_Maps_API_Key,
      PointLatLng(_Google.latitude, _Google.longitude),
      PointLatLng(_ApplePark.latitude, _ApplePark.longitude),
      travelMode: TravelMode.bicycling,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      }
    } else {
      print(result.errorMessage);
    }
    return polylineCoordinates;
  }

  // ignore: non_constant_identifier_names
  void GeneratePolylinesFromPoints(List<LatLng> Polylinecoordinates) async {
    PolylineId id = const PolylineId("Poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: Polylinecoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }
}
