import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CopyrightBadge extends StatelessWidget {
  const CopyrightBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 50,
        width: 180,
        child: SvgPicture.asset(
          'assets/copyright_badge.svg',
          semanticsLabel: 'Copyright Badge',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
