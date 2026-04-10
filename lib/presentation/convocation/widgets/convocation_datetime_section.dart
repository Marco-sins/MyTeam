import 'package:flutter/material.dart';

class ConvocationDateTimeSection extends StatelessWidget {
  final String formattedDate;
  final String formattedMatchTime;
  final String formattedCallTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickMatchTime;
  final VoidCallback onPickCallTime;

  const ConvocationDateTimeSection({
    super.key,
    required this.formattedDate,
    required this.formattedMatchTime,
    required this.formattedCallTime,
    required this.onPickDate,
    required this.onPickMatchTime,
    required this.onPickCallTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: onPickDate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_soccer, size: 18),
                  const SizedBox(width: 4),
                  const Text(
                    'Hora partido:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedMatchTime,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: onPickMatchTime,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.group, size: 18),
                  const SizedBox(width: 4),
                  const Text(
                    'Hora convocatoria:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedCallTime,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.alarm),
                    onPressed: onPickCallTime,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
