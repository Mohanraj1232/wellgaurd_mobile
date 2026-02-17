import 'package:flutter/material.dart';

class AppColors {
  // Background Colors (Dark Navy from logo)
  static const Color bgMain = Color(0xFF0D1421);
  static const Color bgCard = Color(0xFF1A2332);
  static const Color bgHover = Color(0xFF243044);
  static const Color bgGlass = Color(0x1AFFFFFF);
  static const Color bgGlassLight = Color(0x0DFFFFFF);
  static const Color bgGlassDark = Color(0x26000000);

  // Primary Brand Colors (Cyan Blue from logo)
  static const Color primary = Color(0xFF0EA5E9);         // GrievX Cyan Blue
  static const Color primaryLight = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color primaryVeryLight = Color(0xFF7DD3FC);
  static const Color primarySuperDark = Color(0xFF0369A1);

  // Secondary Brand Colors (Orange from logo X)
  static const Color secondary = Color(0xFFF97316);       // GrievX Orange
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFEA580C);
  static const Color secondaryVeryLight = Color(0xFFFDBA74);

  // Accent Colors
  static const Color accentWarning = Color(0xFFF59E0B);
  static const Color accentDanger = Color(0xFFEF4444);
  static const Color accentDangerLight = Color(0xFFFCA5A5);
  static const Color accentDangerDark = Color(0xFFDC2626);
  static const Color accentInfo = Color(0xFF38BDF8);
  static const Color accentSuccess = Color(0xFF22C55E);
  static const Color accentSuccessLight = Color(0xFF86EFAC);

  // Text Colors (for dark theme)
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);

  // Borders
  static const Color borderLight = Color(0xFF334155);
  static const Color borderDark = Color(0xFF475569);
  static const Color borderGlass = Color(0x33FFFFFF);

  // Shadows
  static const Color shadowDark = Color(0x66000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowPrimary = Color(0x660EA5E9);
  static const Color shadowDanger = Color(0x66EF4444);
  static const Color shadowSecondary = Color(0x66F97316);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryLightGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [accentDanger, accentDangerDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [accentSuccess, Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient bgGradient = RadialGradient(
    colors: [Color(0xFF1A2332), bgMain],
    center: Alignment.center,
    radius: 1.5,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x0AFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meshGradient1 = LinearGradient(
    colors: [Color(0x330EA5E9), Color(0x00000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meshGradient2 = LinearGradient(
    colors: [Color(0x33F97316), Color(0x00000000)],
    begin: Alignment.bottomRight,
    end: Alignment.topLeft,
  );

  // Card gradients for glass effect
  static const LinearGradient cardGlassGradient = LinearGradient(
    colors: [Color(0x1A1A2332), Color(0x0D1A2332)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}