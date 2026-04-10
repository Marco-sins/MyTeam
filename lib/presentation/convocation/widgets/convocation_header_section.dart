import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

import 'convocation_map_picker_page.dart';

class ConvocationHeaderSection extends StatelessWidget {
  final TextEditingController rivalController;
  final bool isHome;
  final String? awayLocation;
  final VoidCallback onToggleHomeAway;
  final ValueChanged<String> onAwayLocationSelected;

  const ConvocationHeaderSection({
    super.key,
    required this.rivalController,
    required this.isHome,
    required this.awayLocation,
    required this.onToggleHomeAway,
    required this.onAwayLocationSelected,
  });

  Future<void> _pickAwayLocation(BuildContext context) async {
    final initialLatLng = _parseLatLng(awayLocation);

    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) =>
            ConvocationMapPickerPage(initialLocation: initialLatLng),
      ),
    );

    if (result != null) {
      final value =
          '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
      onAwayLocationSelected(value);
    }
  }

  LatLng? _parseLatLng(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: rivalController,
                  decoration: const InputDecoration(
                    labelText: 'Rival',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onToggleHomeAway,
                icon: Icon(isHome ? Icons.home : Icons.flight_takeoff),
                color: isHome ? Colors.green : Colors.blue,
                tooltip: isHome ? 'Partido en casa' : 'Partido fuera de casa',
              ),
            ],
          ),
        ),
        if (!isHome) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade50,
                    foregroundColor: Colors.blueGrey.shade900,
                  ),
                  onPressed: () => _pickAwayLocation(context),
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Añadir ubicación (Maps)'),
                ),
                if (awayLocation != null && awayLocation!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            awayLocation!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(awayLocation!)}',
                            );
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.map, size: 16),
                          label: const Text(
                            'Ver en Maps',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
