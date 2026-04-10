import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ConvocationMapPickerPage extends StatefulWidget {
  const ConvocationMapPickerPage({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<ConvocationMapPickerPage> createState() =>
      _ConvocationMapPickerPageState();
}

class _ConvocationMapPickerPageState extends State<ConvocationMapPickerPage> {
  late LatLng _center;
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _center =
        widget.initialLocation ??
        const LatLng(40.4168, -3.7038); // Madrid por defecto
    _selected = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _selected ?? _center,
          initialZoom: 13,
          onTap: (tapPosition, latLng) {
            setState(() {
              _selected = latLng;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'football_manager',
          ),
          if (_selected != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selected!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _selected == null
                ? null
                : () {
                    Navigator.of(context).pop(_selected);
                  },
            icon: const Icon(Icons.check),
            label: const Text('Confirmar ubicación'),
          ),
        ),
      ),
    );
  }
}
