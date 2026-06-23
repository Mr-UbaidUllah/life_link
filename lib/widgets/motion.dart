import 'package:flutter/material.dart';

import 'package:blood_donation/theme/theme.dart';

/// Lightweight, dependency-free motion primitives that give the redesigned app
/// its "bold & vibrant" feel — entrance animations, animated counters and a
/// looping pulse for urgent emphasis. All pure Flutter (no extra packages).

/// Fades + slides a child in on first build. Optional [delay] enables
/// staggered list entrances (see [Stagger]).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical offset (logical px) the child travels while fading in.
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.base,
    this.offsetY = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState — NOT a lazy `late` initializer. A lazy field
  // would be constructed the first time it's read, and if the widget is
  // disposed before it's ever read (e.g. a delayed entrance that unmounts
  // before firing), dispose()'s `_c.dispose()` would create the controller
  // against a deactivated element and crash on the TickerMode lookup.
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: AppMotion.standard));

    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Wraps a list of children so each animates in slightly after the previous,
/// producing a cascading entrance. Use inside a [Column]/[ListView].
class Stagger {
  Stagger._();

  /// Returns [children] each wrapped in a [FadeSlideIn] with an increasing
  /// delay. [step] controls the gap between items.
  static List<Widget> children(
    List<Widget> children, {
    Duration step = AppMotion.stagger,
    Duration initialDelay = Duration.zero,
  }) {
    return List.generate(children.length, (i) {
      return FadeSlideIn(
        delay: initialDelay + step * i,
        child: children[i],
      );
    });
  }
}

/// Counts up from 0 to [value] when first shown — used for impact stats so
/// numbers feel alive rather than static.
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  /// Optional formatter (e.g. "1.2K"). Receives the in-progress integer.
  final String Function(int)? formatter;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.count,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: AppMotion.standard,
      builder: (context, v, _) => Text(
        formatter?.call(v) ?? '$v',
        style: style,
      ),
    );
  }
}

/// Continuously pulses its child's scale + opacity — draws the eye to critical
/// / urgent elements (e.g. a live emergency badge).
class Pulse extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double minScale;
  final double maxScale;

  const Pulse({
    super.key,
    required this.child,
    this.enabled = true,
    this.minScale = 1.0,
    this.maxScale = 1.06,
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  // Eager creation in initState (see _FadeSlideInState): a lazy `late` field
  // would be constructed inside dispose() when `enabled` is false (the field is
  // never read in build), crashing on the deactivated-element Ticker lookup.
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Pulse old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.enabled && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// A bouncy tap scale for buttons/cards — shrinks slightly while pressed.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
