import 'package:flutter/material.dart';

const Color primaryDark = Color(0xFF212121);
const Color primaryLight = Color(0xFF343434);

const Color secondaryDark = Color(0xFF8F6BFF);
const Color secondaryLight = Color(0xFF9A7BFF);

const LinearGradient mainGradient = LinearGradient(
  colors: [secondaryDark, secondaryLight],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final ThemeData darkThemeData = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryDark,
  scaffoldBackgroundColor: primaryDark,
  appBarTheme: const AppBarTheme(
    color: primaryLight,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  colorScheme: const ColorScheme.dark(
    primary: primaryLight,
    secondary: secondaryDark,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);
