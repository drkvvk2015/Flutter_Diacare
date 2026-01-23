import 'package:flutter/material.dart';
import 'glassmorphic_card.dart';

/// A reusable dashboard card for admin, pharmacy, and patient dashboards.
class DashboardCard extends StatelessWidget {

  const DashboardCard({
    required this.icon, required this.iconColor, required this.title, required this.subtitle, super.key,
    this.onTap,
    this.cardColor,
    this.borderRadius = 18,
    this.useGlassmorphic = true,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? cardColor;
  final double borderRadius;
  final bool useGlassmorphic;

  @override
  Widget build(BuildContext context) {
    final cardChild = ListTile(
      leading: Icon(icon, color: iconColor, size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
      onTap: onTap,
    );
    if (useGlassmorphic) {
      return GlassmorphicCard(
        key: key,
        borderRadius: borderRadius,
        child: cardChild,
      );
    } else {
      return Card(
        key: key,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: cardChild,
      );
    }
  }
}
