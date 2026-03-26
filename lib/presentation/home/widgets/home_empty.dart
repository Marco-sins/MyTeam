import 'package:flutter/material.dart';

class HomeEmpty extends StatelessWidget {
  const HomeEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Todavía no se han creado equipos",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text("¡Pulsa el botón + para empezar!"),
        ],
      ),
    );
  }
}
