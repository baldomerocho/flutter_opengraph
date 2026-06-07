import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opengraph/src/models/open_graph_entity.dart';
import 'package:opengraph/src/opengraph_fetch_functions.dart';
import 'package:opengraph/src/utils/util.dart';
import 'package:opengraph/src/widget_opengraph.dart';

/// A widget that fetches and displays OpenGraph data
///
/// This widget is a bridge between the old and new functionality
class OpengraphPreview extends StatefulWidget {
  /// URL to fetch the OpenGraph data from
  final String url;

  /// Height of the preview card
  final double height;

  /// Border radius of the preview card
  final double borderRadius;

  /// Background color shown while loading and on error
  final Color backgroundColor;

  /// Color of the loading indicator and the reload button
  final Color progressColor;

  /// Shows a reload button when the fetch fails
  final bool showReloadButton;

  /// Reserved label, kept for backwards compatibility
  final String preview;

  /// Message shown when the fetch fails
  final String error;

  /// Label of the reload button
  final String refresh;

  /// Custom widget shown when the fetch fails. It replaces the whole card,
  /// so the caller has full control (return your own design, or use
  /// [hideOnError] to render nothing at all).
  final Widget? childError;

  /// Custom widget shown while the data is loading, instead of the default
  /// progress indicator.
  final Widget? childPreview;

  /// When true, nothing is rendered if the URL cannot be fetched.
  final bool hideOnError;

  /// Custom widget shown when the page has no og:image (or it fails to
  /// load), instead of the default bundled image.
  final Widget? fallbackImage;

  /// Whether the text overlay uses a blur effect. Disable it in long lists
  /// for better scrolling performance ([BackdropFilter] is expensive).
  final bool enableBlur;

  const OpengraphPreview({
    super.key,
    required this.url,
    this.height = 200,
    this.borderRadius = 10,
    this.backgroundColor = Colors.black87,
    this.progressColor = Colors.white54,
    this.showReloadButton = false,
    this.preview = "Preview",
    this.error = "Error on fetch OpenGraph",
    this.refresh = "Refresh",
    this.childError,
    this.childPreview,
    this.hideOnError = false,
    this.fallbackImage,
    this.enableBlur = true,
  });

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
    _future = _fetch();
  }

  @override
  void didUpdateWidget(OpengraphPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = _fetch();
    }
  }

  Future<OpenGraphEntity?> _fetch() {
    final future = opengraph_fetch(widget.url, throwOnError: true);
    // FutureBuilder only subscribes on the next build; if the fetch fails
    // before that, the error would be reported as unhandled. Mark it
    // handled here — FutureBuilder still receives it and shows the error.
    future.ignore();
    return future;
  }

  void _retry() {
    // The cache normalizes its keys, so the raw widget URL addresses the
    // same entry the fetch stored.
    OpengraphCache.evict(widget.url);
    setState(() {
      _future = _fetch();
    });
  }

  /// Card chrome (margin, background and rounded corners) around [child].
  Widget _decorated(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: child,
      ),
    );
  }

  Widget _loadingContent() {
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: widget.childPreview ??
          Center(
            child: CircularProgressIndicator(
              color: widget.progressColor,
            ),
          ),
    );
  }

  Widget _errorContent() {
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.error,
              style: TextStyle(color: Colors.pink.shade200),
            ),
            if (widget.showReloadButton)
              TextButton.icon(
                onPressed: _retry,
                icon: Icon(Icons.refresh, color: widget.progressColor),
                label: Text(
                  widget.refresh,
                  style: TextStyle(color: widget.progressColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Same fallback the fetcher used to produce on network errors: the
  /// domain as title and the URL itself as description.
  OpenGraphEntity _fallbackEntity() {
    final target = normalizeUrl(widget.url) ?? widget.url;
    return OpenGraphEntity(
      title: getDomain(target) ?? target,
      description: target,
      image: '',
      url: target,
      locale: 'en_US',
      type: 'website',
      siteName: '',
    );
  }

  Widget _preview(OpenGraphEntity data) {
    return WidgetOpenGraph(
      data: data,
      height: widget.height,
      isProduction: true,
      borderRadius: widget.borderRadius,
      fallbackImage: widget.fallbackImage,
      enableBlur: widget.enableBlur,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpenGraphEntity?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _decorated(_loadingContent());
        }

        if (snapshot.hasError || snapshot.data == null) {
          if (widget.hideOnError) return const SizedBox.shrink();
          if (widget.childError != null) return widget.childError!;
          // Network/HTTP errors keep the previous default: a degraded
          // preview built from the URL — unless the caller opted into the
          // reload button, which needs the error UI to be visible.
          if (snapshot.hasError && !widget.showReloadButton) {
            return _decorated(_preview(_fallbackEntity()));
          }
          return _decorated(_errorContent());
        }

        return _decorated(_preview(snapshot.data!));
      },
    );
  }
}
