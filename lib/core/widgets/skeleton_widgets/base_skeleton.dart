import 'package:flutter/material.dart';

/// Configuration for skeleton loading UI
class SkeletonConfig {
  /// Enable skeleton loading
  static const bool enabled = true;

  /// Light gray for skeleton elements
  static const Color baseColor = Color(0xFFF0F0F0);

  /// Slightly darker for depth
  static const Color highlightColor = Color(0xFFE8E8E8);

  /// Duration of animation
  static const Duration animationDuration = Duration(milliseconds: 1200);

  /// Border radius for skeleton elements
  static const double defaultBorderRadius = 8.0;

  /// Vertical spacing between skeleton items
  static const double itemSpacing = 12.0;

  /// Horizontal padding for skeleton content
  static const double contentPadding = 16.0;
}

/// Base class for creating skeleton loaders
class BaseSkeleton extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget skeletonChild;

  const BaseSkeleton({
    Key? key,
    required this.isLoading,
    required this.child,
    required this.skeletonChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading ? skeletonChild : child,
    );
  }
}

/// Reusable skeleton bone (placeholder element)
class SkeletonBone extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBone({
    Key? key,
    required this.height,
    this.width = double.infinity,
    BorderRadius? borderRadius,
    this.margin,
  })  : borderRadius = borderRadius ?? const BorderRadius.all(
          Radius.circular(SkeletonConfig.defaultBorderRadius),
        ),
        super(key: key);

  @override
  State<SkeletonBone> createState() => _SkeletonBoneState();
}

class _SkeletonBoneState extends State<SkeletonBone>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: SkeletonConfig.animationDuration,
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                SkeletonConfig.baseColor,
                SkeletonConfig.highlightColor,
                SkeletonConfig.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Circular skeleton bone (for avatars, profile pictures)
class SkeletonCircle extends StatefulWidget {
  final double radius;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    Key? key,
    required this.radius,
    this.margin,
  }) : super(key: key);

  @override
  State<SkeletonCircle> createState() => _SkeletonCircleState();
}

class _SkeletonCircleState extends State<SkeletonCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: SkeletonConfig.animationDuration,
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          margin: widget.margin,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(
                (_shimmerAnimation.value * 2) - 1,
                (_shimmerAnimation.value * 2) - 1,
              ),
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                SkeletonConfig.baseColor,
                SkeletonConfig.highlightColor,
                SkeletonConfig.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Multi-line skeleton for text content
class SkeletonLine extends StatelessWidget {
  final int lineCount;
  final double? width;
  final double height;
  final double spacing;
  final bool endWithShortLine;

  const SkeletonLine({
    Key? key,
    this.lineCount = 3,
    this.width,
    this.height = 12.0,
    this.spacing = SkeletonConfig.itemSpacing,
    this.endWithShortLine = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lineCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < lineCount - 1 ? spacing : 0),
          child: SkeletonBone(
            width: endWithShortLine && index == lineCount - 1
                ? (width ?? 150)
                : (width ?? double.infinity),
            height: height,
          ),
        ),
      ),
    );
  }
}

/// Extension for easy loading state management
extension SkeletonLoaderExt on Widget {
  Widget withSkeleton({
    required bool isLoading,
    required Widget skeleton,
  }) {
    return BaseSkeleton(
      isLoading: isLoading,
      child: this,
      skeletonChild: skeleton,
    );
  }
}
