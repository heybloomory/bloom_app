import 'package:flutter/material.dart';

final ThemeData lightThemeData = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  colorScheme: const ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.amber,
  ),
);
