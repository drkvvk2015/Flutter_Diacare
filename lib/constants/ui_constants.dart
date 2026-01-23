/// UI Constants
/// 
/// Constants for UI dimensions, spacing, and styling.
library;

import 'package:flutter/material.dart';

/// UI-related constants
class UIConstants {
  UIConstants._(); // Private constructor

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacing2Xl = 48;

  // Border Radius
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;

  // Icon Sizes
  static const double iconSizeXs = 16;
  static const double iconSizeSm = 20;
  static const double iconSizeMd = 24;
  static const double iconSizeLg = 32;
  static const double iconSizeXl = 48;
  static const double iconSize2Xl = 64;

  // Font Sizes
  static const double fontSizeXs = 10;
  static const double fontSizeSm = 12;
  static const double fontSizeMd = 14;
  static const double fontSizeLg = 16;
  static const double fontSizeXl = 18;
  static const double fontSize2Xl = 20;
  static const double fontSize3Xl = 24;
  static const double fontSize4Xl = 30;
  static const double fontSize5Xl = 36;

  // Button Heights
  static const double buttonHeightSm = 32;
  static const double buttonHeightMd = 44;
  static const double buttonHeightLg = 56;

  // Input Heights
  static const double inputHeightSm = 36;
  static const double inputHeightMd = 48;
  static const double inputHeightLg = 56;

  // Card Dimensions
  static const double cardElevation = 2;
  static const double cardElevationHover = 8;
  static const double cardPadding = 16;

  // App Bar
  static const double appBarHeight = 56;
  static const double appBarElevation = 0;

  // Bottom Navigation
  static const double bottomNavHeight = 64;

  // Drawer
  static const double drawerWidth = 280;

  // Avatar Sizes
  static const double avatarSizeXs = 24;
  static const double avatarSizeSm = 32;
  static const double avatarSizeMd = 48;
  static const double avatarSizeLg = 64;
  static const double avatarSizeXl = 96;

  // Progress Indicators
  static const double progressIndicatorSize = 24;
  static const double progressIndicatorStrokeWidth = 3;

  // Divider
  static const double dividerThickness = 1;
  static const double dividerIndent = 16;

  // List Tile
  static const double listTileHeight = 56;
  static const double listTilePadding = 16;

  // Dialog
  static const double dialogMaxWidth = 400;
  static const double dialogPadding = 24;

  // Snackbar
  static const double snackbarHeight = 48;
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Breakpoints (for responsive design)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Grid
  static const int gridCrossAxisCountMobile = 2;
  static const int gridCrossAxisCountTablet = 3;
  static const int gridCrossAxisCountDesktop = 4;
  static const double gridSpacing = 16;

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
