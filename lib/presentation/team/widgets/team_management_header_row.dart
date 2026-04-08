import 'dart:io';

import 'package:flutter/material.dart';

class TeamManagementHeaderRow extends StatelessWidget {
  final TextEditingController nameController;
  final String? selectedLogoPath;
  final String? logoUrl;
  final VoidCallback? onLogoTap;

  const TeamManagementHeaderRow({
    super.key,
    required this.nameController,
    required this.selectedLogoPath,
    required this.logoUrl,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onLogoTap,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: selectedLogoPath != null
                ? FileImage(File(selectedLogoPath!))
                : (logoUrl != null &&
                          logoUrl!.isNotEmpty &&
                          (logoUrl!.startsWith('http://') ||
                              logoUrl!.startsWith('https://'))
                      ? NetworkImage(logoUrl!)
                      : null),
            child: selectedLogoPath == null || selectedLogoPath!.isEmpty
                ? const Icon(Icons.shield_outlined)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del equipo',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
