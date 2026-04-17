import 'dart:io';

import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final hasLocal = selectedLogoPath != null && selectedLogoPath!.isNotEmpty;
    final hasRemote = logoUrl != null &&
        logoUrl!.isNotEmpty &&
        (logoUrl!.startsWith('http://') || logoUrl!.startsWith('https://'));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onLogoTap,
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: hasLocal
                      ? Image.file(
                          File(selectedLogoPath!),
                          fit: BoxFit.cover,
                        )
                      : hasRemote
                          ? Image.network(
                              logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 40,
                                  color: scheme.primary,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.teamManagementLogoLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              l10n.teamManagementLogoTapHint,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.teamManagementNameLabel,
              hintText: l10n.teamManagementNameHint,
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
  }
}
