import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';

class WebSmoothScrollWrapper extends StatefulWidget {
  final Widget child;

  const WebSmoothScrollWrapper({super.key, required this.child});

  @override
  State<WebSmoothScrollWrapper> createState() => _WebSmoothScrollWrapperState();
}

class _WebSmoothScrollWrapperState extends State<WebSmoothScrollWrapper> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return widget.child;
    }

    return ScrollConfiguration(
      behavior: const _NoGlowBehavior(),
      child: WebSmoothScroll(
        controller: _controller,
        child: PrimaryScrollController(
          controller: _controller,
          child: widget.child,
        ),
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
