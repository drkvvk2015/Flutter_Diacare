/// UI Constants
/// 
/// Constants for UI dimensions, spacing, and styling.

import 'package:flutter/material.dart';

/// UI-related constants
class UIConstants {
  UIConstants._(); // Private constructor

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacing2Xl = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;

  // Icon Sizes
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;
  static const double iconSize2Xl = 64.0;

  // Font Sizes
  static const double fontSizeXs = 10.0;
  static const double fontSizeSm = 12.0;
  static const double fontSizeMd = 14.0;
  static const double fontSizeLg = 16.0;
  static const double fontSizeXl = 18.0;
  static const double fontSize2Xl = 20.0;
  static const double fontSize3Xl = 24.0;
  static const double fontSize4Xl = 30.0;
  static const double fontSize5Xl = 36.0;

  // Button Heights
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 56.0;

  // Input Heights
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 48.0;
  static const double inputHeightLg = 56.0;

  // Card Dimensions
  static const double cardElevation = 2.0;
  static const double cardElevationHover = 8.0;
  static const double cardPadding = 16.0;

  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;

  // Bottom Navigation
  static const double bottomNavHeight = 64.0;

  // Drawer
  static const double drawerWidth = 280.0;

  // Avatar Sizes
  static const double avatarSizeXs = 24.0;
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
  static const double avatarSizeXl = 96.0;

  // Progress Indicators
  static const double progressIndicatorSize = 24.0;
  static const double progressIndicatorStrokeWidth = 3.0;

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 16.0;

  // List Tile
  static const double listTileHeight = 56.0;
  static const double listTilePadding = 16.0;

  // Dialog
  static const double dialogMaxWidth = 400.0;
  static const double dialogPadding = 24.0;

  // Snackbar
  static const double snackbarHeight = 48.0;
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Breakpoints (for responsive design)
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Grid
  static const int gridCrossAxisCountMobile = 2;
  static const int gridCrossAxisCountTablet = 3;
  static const int gridCrossAxisCountDesktop = 4;
  static const double gridSpacing = 16.0;

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Opacity
  static const double opacityDisabled = 0.38;
  static const double opacityHover = 0.08;
  static const double opacityPressed = 0.12;

  // Z-Index (for stacking)
  static const int zIndexDropdown = 1000;
  static const int zIndexModal = 2000;
  static const int zIndexToast = 3000;
  static const int zIndexTooltip = 4000;
}
