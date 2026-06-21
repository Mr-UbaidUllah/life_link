import 'package:flutter/material.dart';

/// Wraps non-scrolling content (empty / error / "no results" states) so that a
/// surrounding [RefreshIndicator] can still be triggered by a pull gesture —
/// a plain Center can't be over-scrolled, which would otherwise make
/// pull-to-refresh impossible whenever a list is empty.
class RefreshableFill extends StatelessWidget {
  final Widget child;
  const RefreshableFill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}
