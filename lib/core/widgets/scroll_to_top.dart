import 'package:flutter/material.dart';

import 'package:nesherprints/core/strings/app_strings.dart';
import 'package:nesherprints/core/theme/app_theme.dart';
import 'package:nesherprints/core/utils/responsive.dart';

/// Envuelve una lista larga y muestra un botón «Subir al principio» cuando
/// se ha bajado bastante. [builder] recibe el controlador que hay que dar al
/// scrollable.
class ScrollToTop extends StatefulWidget {
  const ScrollToTop({super.key, required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  /// Desplazamiento a partir del cual aparece el botón.
  static const double threshold = 480;

  @override
  State<ScrollToTop> createState() => _ScrollToTopState();
}

class _ScrollToTopState extends State<ScrollToTop> {
  final _controller = ScrollController();
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show =
        _controller.hasClients && _controller.offset > ScrollToTop.threshold;
    if (show != _visible) setState(() => _visible = show);
  }

  Future<void> _goTop() => _controller.animateTo(
    0,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    // En móvil a la izquierda, para no chocar con el botón «+» flotante.
    final alignment = context.isCompact
        ? Alignment.bottomLeft
        : Alignment.bottomRight;
    return Stack(
      children: [
        widget.builder(context, _controller),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_visible,
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.small(
                    heroTag: null,
                    tooltip: AppStrings.scrollToTop,
                    onPressed: _goTop,
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
