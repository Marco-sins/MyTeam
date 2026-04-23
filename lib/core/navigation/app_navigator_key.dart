import 'package:flutter/material.dart';

/// Clave global para resolver [BuildContext] / [AppLocalizations] sin pantalla activa.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
