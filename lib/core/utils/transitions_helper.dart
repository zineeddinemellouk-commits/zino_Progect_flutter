import 'package:flutter/material.dart';

/// Smooth page transitions utility
class SmoothTransitions {
  /// Duration for all transitions (250ms - smooth but not slow)
  static const Duration transitionDuration = Duration(milliseconds: 250);

  /// Fade transition (fade in/out)
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget Function(BuildContext) builder,
    Duration duration = transitionDuration,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      settings: settings,
    );
  }

  /// Slide transition (from right to left)
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget Function(BuildContext) builder,
    Duration duration = transitionDuration,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          ),
          child: child,
        );
      },
      settings: settings,
    );
  }

  /// Slide + Fade transition (combined for smooth effect)
  static PageRouteBuilder<T> slideFadeTransition<T>({
    required Widget Function(BuildContext) builder,
    Duration duration = transitionDuration,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.3, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOutCubic)),
            ),
            child: child,
          ),
        );
      },
      settings: settings,
    );
  }

  /// Scale + Fade transition (grow effect)
  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget Function(BuildContext) builder,
    Duration duration = transitionDuration,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      settings: settings,
    );
  }

  /// Rotate + Fade transition (rotation effect)
  static PageRouteBuilder<T> rotateTransition<T>({
    required Widget Function(BuildContext) builder,
    Duration duration = transitionDuration,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: animation.drive(
            Tween<double>(
              begin: -0.1,
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeInOutBack)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      settings: settings,
    );
  }
}

/// Dialog animations utility
class DialogTransitions {
  /// Smooth dialog entrance
  static Future<T?> showWithTransition<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOutCubic,
  }) {
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionDuration: duration,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).chain(CurveTween(curve: curve)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.3),
    );
  }
}

/// Extension for easy navigation with smooth transitions
extension SmoothNavigation on BuildContext {
  /// Navigate with fade transition
  Future<T?> pushWithFade<T>(
    Widget Function(BuildContext) builder, {
    bool replace = false,
  }) {
    final route = SmoothTransitions.fadeTransition<T>(
      builder: builder,
    );
    return replace
        ? Navigator.of(this).pushReplacement<T, T>(route)
        : Navigator.of(this).push<T>(route);
  }

  /// Navigate with slide transition
  Future<T?> pushWithSlide<T>(
    Widget Function(BuildContext) builder, {
    bool replace = false,
  }) {
    final route = SmoothTransitions.slideTransition<T>(
      builder: builder,
    );
    return replace
        ? Navigator.of(this).pushReplacement<T, T>(route)
        : Navigator.of(this).push<T>(route);
  }

  /// Navigate with slide+fade transition
  Future<T?> pushWithSlideFade<T>(
    Widget Function(BuildContext) builder, {
    bool replace = false,
  }) {
    final route = SmoothTransitions.slideFadeTransition<T>(
      builder: builder,
    );
    return replace
        ? Navigator.of(this).pushReplacement<T, T>(route)
        : Navigator.of(this).push<T>(route);
  }

  /// Navigate with scale transition
  Future<T?> pushWithScale<T>(
    Widget Function(BuildContext) builder, {
    bool replace = false,
  }) {
    final route = SmoothTransitions.scaleTransition<T>(
      builder: builder,
    );
    return replace
        ? Navigator.of(this).pushReplacement<T, T>(route)
        : Navigator.of(this).push<T>(route);
  }

  /// Navigate with rotate transition
  Future<T?> pushWithRotate<T>(
    Widget Function(BuildContext) builder, {
    bool replace = false,
  }) {
    final route = SmoothTransitions.rotateTransition<T>(
      builder: builder,
    );
    return replace
        ? Navigator.of(this).pushReplacement<T, T>(route)
        : Navigator.of(this).push<T>(route);
  }

  /// Show dialog with smooth animation
  Future<T?> showDialogWithTransition<T>(
    WidgetBuilder builder,
  ) {
    return DialogTransitions.showWithTransition<T>(
      context: this,
      builder: builder,
    );
  }
}
