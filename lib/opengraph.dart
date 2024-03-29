///
/// @project  : opengraph
/// @author   : Baldomero (datogedon@gmail.com)
/// @link     : https://github.com/baldomerocho/flutter_opengraph/
/// @Disc     : a dart and flutter package to fetch and preview OpenGraph data
///
library opengraph;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:opengraph/entities/open_graph_entity.dart';

import 'src/fetch_opengraph.dart';
import 'src/salve_objetcts.dart';
import 'src/widget_opengraph.dart';
export 'src/fetch_opengraph.dart';

class OpenGraphPreview extends StatefulWidget {
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
  final OpenGraphRequestInterface? provider;

  ///
  /// This constructor will create an OpenGraphPreview instance.
  ///
  /// All parameters are mandatory however [height],
  /// [borderRadius], [backgroundColor], [progressColor], [showReloadButton],
  /// [preview], [error], [refresh], [childError], [childPreview] have a default values, so can be ignored.
  /// Will throw an exception if the line above isn't satisfied.
  ///
  const OpenGraphPreview({
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
    this.childError = const SizedBox.shrink(),
    this.childPreview = const SizedBox.shrink(),
    //OpenGraphRequest
    this.provider,
  });

  @override
  State<OpenGraphPreview> createState() => _OpenGraphPreviewState();
}

class _OpenGraphPreviewState extends State<OpenGraphPreview> {
  late OpenGraphRequestInterface defaultProvider;
  bool _isProduction = true;

  @override
  void initState() {
    defaultProvider = widget.provider ?? OpenGraphRequest();
    _isProduction = defaultProvider is OpenGraphRequest;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<OpenGraphEntity?> future() {
      return defaultProvider.fetch(widget.url);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: FutureBuilder(
            future: future(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                    height: widget.height,
                    color: widget.backgroundColor,
                    child: Center(
                        child: CupertinoActivityIndicator(
                      color: widget.progressColor,
                    )));
              }

              if (snapshot.hasError &&
                  !snapshot.hasData &&
                  snapshot.data == null) {
                return Container(
                    height: widget.height,
                    color: widget.backgroundColor,
                    child: Center(
                        child: Text(widget.error,
                            style: TextStyle(color: Colors.pink.shade200))));
              }

              if (snapshot.data == null) {
                var data = SalveObjects.notResults;
                data.title = widget.error;
                return WidgetOpenGraph(
                    data: data,
                    height: widget.height,
                    isProduction: _isProduction,
                    borderRadius: widget.borderRadius);
              }

              final data = snapshot.data as OpenGraphEntity;

              return WidgetOpenGraph(
                data: data,
                height: widget.height,
                isProduction: _isProduction,
                borderRadius: widget.borderRadius,
              );
            }),
      ),
    );
  }
}
