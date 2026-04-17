import 'package:flutter/material.dart';
import 'package:football_manager/presentation/common/widgets/app_language_selector.dart';

/// Selector de idioma (ES / EN / FR / IT) en la [AppBar] de la home.
class HomeLanguageSelector extends StatelessWidget {
  const HomeLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 4),
      child: AppLanguageSelector(
        variant: AppLanguageSelectorVariant.appBar,
      ),
    );
  }
}
