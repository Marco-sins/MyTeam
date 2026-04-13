import 'package:flutter/material.dart';
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
            child: SizedBox(
              height: 40,
              child: TextFormField(
                initialValue: awayLocation ?? '',
                decoration: const InputDecoration(
                  labelText: 'Enlace o dirección',
                  border: OutlineInputBorder(),
                  hintText: 'Pega el enlace o dirección',
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  isDense: true,
                ),
                onChanged: onAwayLocationSelected,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
