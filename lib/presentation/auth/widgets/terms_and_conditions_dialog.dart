import 'package:flutter/material.dart';
import 'package:football_manager/l10n/app_localizations.dart';

class TermsAndConditionsDialog extends StatelessWidget {
  const TermsAndConditionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              l10n.termsAndConditionsTitle,
              style: textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.termsAndConditionsContent,
                style: textTheme.bodyMedium,
              ),
            ),
          ),
          // Footer buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.termsAndConditionsDecline),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.termsAndConditionsAccept),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Show terms and conditions dialog and return true if accepted, false otherwise
Future<bool?> showTermsAndConditionsDialog(BuildContext context) {
  return showDialog<bool?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const TermsAndConditionsDialog(),
  );
}
