import 'package:flutter/material.dart';

class AttendanceTableHeader extends StatelessWidget {
  const AttendanceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Divider(height: 1),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '#',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Jugador',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  'Asiste',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  'Ausencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),
      ],
    );
  }
}
