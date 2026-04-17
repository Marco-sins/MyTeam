import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';

class ConvocationMapPickerPage extends StatefulWidget {
  const ConvocationMapPickerPage({super.key, this.initialLocation});

  final ll.LatLng? initialLocation;

  @override
  State<ConvocationMapPickerPage> createState() =>
      _ConvocationMapPickerPageState();
}

class _ConvocationMapPickerPageState extends State<ConvocationMapPickerPage> {
  late gmaps.LatLng _center;
  gmaps.LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _center = widget.initialLocation != null
        ? gmaps.LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          )
        : const gmaps.LatLng(40.4168, -3.7038); // Madrid por defecto
    _selected = widget.initialLocation != null
        ? gmaps.LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          )
        : null;

    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final current = gmaps.LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _center = current;
        _selected ??= current;
      });
    } catch (_) {
      // Si falla, simplemente nos quedamos con el centro por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.screenSelectLocation),
      ),
      body: gmaps.GoogleMap(
        initialCameraPosition: gmaps.CameraPosition(
          target: _selected ?? _center,
          zoom: 14,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onTap: (latLng) {
          setState(() {
            _selected = latLng;
          });
        },
        markers: _selected == null
            ? {}
            : {
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('selected'),
                  position: _selected!,
                ),
              },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _selected == null
                  ? null
                  : () {
                      final result = ll.LatLng(
                        _selected!.latitude,
                        _selected!.longitude,
                      );
                      Navigator.of(context).pop(result);
                    },
              icon: const Icon(Icons.check),
              label: const Text('Confirmar ubicación'),
            ),
          ),
        ),
      ),
    );
  }
}
