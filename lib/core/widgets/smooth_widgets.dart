import 'package:flutter/material.dart';

/// Widget that provides smooth tap feedback with scale animation
class SmoothButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final Duration animationDuration;

  const SmoothButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.all(0),
    this.enabled = true,
    this.animationDuration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<SmoothButton> createState() => _SmoothButtonState();
}

class _SmoothButtonState extends State<SmoothButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      reverseDuration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPress() {
    if (!widget.enabled) return;

    _controller.forward().then((_) {
      _controller.reverse();
      widget.onPressed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onPress,
      behavior: HitTestBehavior.translucent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: widget.padding,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.6,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Enhanced ListTile with tap feedback
class SmoothListTile extends StatefulWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final EdgeInsets contentPadding;

  const SmoothListTile({
    Key? key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  }) : super(key: key);

  @override
  State<SmoothListTile> createState() => _SmoothListTileState();
}

class _SmoothListTileState extends State<SmoothListTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (pressed) {
          setState(() => _isPressed = pressed);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isPressed
                ? Colors.black.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Padding(
            padding: widget.contentPadding,
            child: Row(
              children: [
                widget.leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Smooth loading overlay that fades in/out
class SmoothLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Duration animationDuration;

  const SmoothLoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedOpacity(
          opacity: isLoading ? 1.0 : 0.0,
          duration: animationDuration,
          child: IgnorePointer(
            ignoring: !isLoading,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Animated expandable section
class SmoothExpandableSection extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;
  final Duration animationDuration;
  final IconData Function(bool) icon;

  const SmoothExpandableSection({
    Key? key,
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
    this.animationDuration = const Duration(milliseconds: 300),
    this.icon = _defaultIcon,
  }) : super(key: key);

  static IconData _defaultIcon(bool expanded) {
    return expanded ? Icons.expand_less : Icons.expand_more;
  }

  @override
  State<SmoothExpandableSection> createState() =>
      _SmoothExpandableSectionState();
}

class _SmoothExpandableSectionState extends State<SmoothExpandableSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );

    _heightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _heightAnimation,
                    child: Icon(widget.icon(_isExpanded)),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: SizeTransition(
            sizeFactor: _heightAnimation,
            child: widget.content,
          ),
        ),
      ],
    );
  }
}

/// Animated fade transition for list items
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final int delay;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = 0,
  }) : super(key: key);

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
