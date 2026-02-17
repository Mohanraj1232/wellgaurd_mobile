import 'package:flutter/material.dart';

/// 8px grid-based spacing system
class AppSpacing {
  // Base unit
  static const double unit = 8.0;

  // Spacing values
  static const double xxs = 4.0;   // 0.5 unit
  static const double xs = 8.0;    // 1 unit
  static const double sm = 12.0;   // 1.5 units
  static const double md = 16.0;   // 2 units
  static const double lg = 20.0;   // 2.5 units
  static const double xl = 24.0;   // 3 units
  static const double xxl = 32.0;  // 4 units
  static const double xxxl = 40.0; // 5 units
  static const double huge = 48.0; // 6 units
  static const double mega = 64.0; // 8 units

  // Padding presets
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets paddingHXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHXL = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets paddingHXXL = EdgeInsets.symmetric(horizontal: xxl);

  // Vertical padding
  static const EdgeInsets paddingVXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVXL = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets paddingVXXL = EdgeInsets.symmetric(vertical: xxl);

  // Screen padding (standard page padding)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg, vertical: xl);
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: lg);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  // Gap sizes for spacing between elements
  static const SizedBox gapXXS = SizedBox(height: xxs, width: xxs);
  static const SizedBox gapXS = SizedBox(height: xs, width: xs);
  static const SizedBox gapSM = SizedBox(height: sm, width: sm);
  static const SizedBox gapMD = SizedBox(height: md, width: md);
  static const SizedBox gapLG = SizedBox(height: lg, width: lg);
  static const SizedBox gapXL = SizedBox(height: xl, width: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl, width: xxl);
  static const SizedBox gapXXXL = SizedBox(height: xxxl, width: xxxl);

  // Vertical gaps
  static const SizedBox vGapXXS = SizedBox(height: xxs);
  static const SizedBox vGapXS = SizedBox(height: xs);
  static const SizedBox vGapSM = SizedBox(height: sm);
  static const SizedBox vGapMD = SizedBox(height: md);
  static const SizedBox vGapLG = SizedBox(height: lg);
  static const SizedBox vGapXL = SizedBox(height: xl);
  static const SizedBox vGapXXL = SizedBox(height: xxl);
  static const SizedBox vGapXXXL = SizedBox(height: xxxl);
  static const SizedBox vGapHuge = SizedBox(height: huge);

  // Horizontal gaps
  static const SizedBox hGapXXS = SizedBox(width: xxs);
  static const SizedBox hGapXS = SizedBox(width: xs);
  static const SizedBox hGapSM = SizedBox(width: sm);
  static const SizedBox hGapMD = SizedBox(width: md);
  static const SizedBox hGapLG = SizedBox(width: lg);
  static const SizedBox hGapXL = SizedBox(width: xl);
  static const SizedBox hGapXXL = SizedBox(width: xxl);

  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 100.0;

  // BorderRadius presets
  static final BorderRadius borderRadiusXS = BorderRadius.circular(radiusXS);
  static final BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);
  static final BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);
  static final BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderRadiusXXL = BorderRadius.circular(radiusXXL);
  static final BorderRadius borderRadiusRound = BorderRadius.circular(radiusRound);

  // Touch targets (minimum 48x48 for accessibility)
  static const double minTouchTarget = 48.0;
  static const double iconButtonSize = 48.0;
  static const double fabSize = 56.0;
  static const double fabSizeLarge = 72.0;

  // Icon sizes
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 28.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 40.0;
  static const double iconHuge = 48.0;

  // Avatar sizes
  static const double avatarSM = 32.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 48.0;
  static const double avatarXL = 64.0;
  static const double avatarXXL = 80.0;

  // Button heights
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 44.0;
  static const double buttonHeightLG = 52.0;
  static const double buttonHeightXL = 60.0;

  // === Compatibility aliases (alternative naming) ===
  
  // All-direction padding aliases
  static const EdgeInsets allXS = paddingXS;
  static const EdgeInsets allSM = paddingSM;
  static const EdgeInsets allMD = paddingMD;
  static const EdgeInsets allLG = paddingLG;
  static const EdgeInsets allXL = paddingXL;
  static const EdgeInsets allXXL = paddingXXL;

  // Horizontal padding aliases
  static const EdgeInsets horizontalXS = paddingHXS;
  static const EdgeInsets horizontalSM = paddingHSM;
  static const EdgeInsets horizontalMD = paddingHMD;
  static const EdgeInsets horizontalLG = paddingHLG;
  static const EdgeInsets horizontalXL = paddingHXL;
  static const EdgeInsets horizontalXXL = paddingHXXL;

  // Vertical padding aliases
  static const EdgeInsets verticalXS = paddingVXS;
  static const EdgeInsets verticalSM = paddingVSM;
  static const EdgeInsets verticalMD = paddingVMD;
  static const EdgeInsets verticalLG = paddingVLG;
  static const EdgeInsets verticalXL = paddingVXL;
  static const EdgeInsets verticalXXL = paddingVXXL;

  // Bottom-only padding
  static const EdgeInsets bottomXS = EdgeInsets.only(bottom: xs);
  static const EdgeInsets bottomSM = EdgeInsets.only(bottom: sm);
  static const EdgeInsets bottomMD = EdgeInsets.only(bottom: md);
  static const EdgeInsets bottomLG = EdgeInsets.only(bottom: lg);
  static const EdgeInsets bottomXL = EdgeInsets.only(bottom: xl);

  // Top-only padding
  static const EdgeInsets topXS = EdgeInsets.only(top: xs);
  static const EdgeInsets topSM = EdgeInsets.only(top: sm);
  static const EdgeInsets topMD = EdgeInsets.only(top: md);
  static const EdgeInsets topLG = EdgeInsets.only(top: lg);
  static const EdgeInsets topXL = EdgeInsets.only(top: xl);

  // Left-only padding
  static const EdgeInsets leftXS = EdgeInsets.only(left: xs);
  static const EdgeInsets leftSM = EdgeInsets.only(left: sm);
  static const EdgeInsets leftMD = EdgeInsets.only(left: md);
  static const EdgeInsets leftLG = EdgeInsets.only(left: lg);
  static const EdgeInsets leftXL = EdgeInsets.only(left: xl);

  // Right-only padding
  static const EdgeInsets rightXS = EdgeInsets.only(right: xs);
  static const EdgeInsets rightSM = EdgeInsets.only(right: sm);
  static const EdgeInsets rightMD = EdgeInsets.only(right: md);
  static const EdgeInsets rightLG = EdgeInsets.only(right: lg);
  static const EdgeInsets rightXL = EdgeInsets.only(right: xl);

  // Radius aliases
  static const double radiusFull = radiusRound;
}
