import 'package:flutter/material.dart';
import 'package:opengraph/src/models/open_graph_entity.dart';
import 'package:opengraph/src/opengraph_fetch_functions.dart';
import 'package:opengraph/src/widget_opengraph.dart';

/// A widget that fetches and displays OpenGraph data
///
/// This widget is a bridge between the old and new functionality
class OpengraphPreview extends StatefulWidget {
  final String url;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final Color progressColor;
  final bool showReloadButton;
  final String preview;
  final String error;
  final String refresh;
  final Widget childError;
  final Widget childPreview;

  const OpengraphPreview({
    Key? key,
    required this.url,
    this.height = 200,
    this.borderRadius = 10,
    this.backgroundColor = Colors.black87,
    this.progressColor = Colors.white54,
    this.showReloadButton = false,
    this.preview = "Preview",
    this.error = "Error on fetch OpenGraph",
    this.refresh = "Refresh",
    this.childError = const SizedBox.shrink(),
    this.childPreview = const SizedBox.shrink(),
  }) : super(key: key);

  @override
  State<OpengraphPreview> createState() => _OpengraphPreviewState();
}

class _OpengraphPreviewState extends State<OpengraphPreview> {
  /// Memoized future: created once per URL instead of on every build, so
  /// rebuilds (e.g. scrolling inside lists) do not trigger new fetches.
  late Future<OpenGraphEntity?> _future;

  @override
  void initState() {
    super.initState();
    _future = opengraph_fetch(widget.url);
  }

  @override
  void didUpdateWidget(OpengraphPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = opengraph_fetch(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: FutureBuilder<OpenGraphEntity?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: widget.height,
                color: widget.backgroundColor,
                child: Center(
                  child: CircularProgressIndicator(
                    color: widget.progressColor,
                  ),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return Container(
                height: widget.height,
                color: widget.backgroundColor,
                child: Center(
                  child: Text(
                    widget.error,
                    style: TextStyle(color: Colors.pink.shade200),
                  ),
                ),
              );
            }

            final data = snapshot.data!;

            return WidgetOpenGraph(
              data: data,
              height: widget.height,
              isProduction: true,
              borderRadius: widget.borderRadius,
            );
          },
        ),
      ),
    );
  }
}
