import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ========================================
// Skeleton Box
// Lightweight shimmer placeholder used in
// list items, cards, and loading panels.
// ========================================

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EEF7),
      highlightColor: const Color(0xFFF1F5F9),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF7),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
