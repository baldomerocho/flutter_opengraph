import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:opengraph/entities/open_graph_entity.dart';

/// WidgetOpenGraph Widget
/// Internal widget to show the OpenGraphEntity data
/// This widget is used by OpenGraphPreview
class WidgetOpenGraph extends StatelessWidget {
  /// OpenGraphEntity data
  final OpenGraphEntity data;

  /// Height of the widget
  final double height;

  /// Is production mode
  final bool isProduction;

  /// Border radius of the widget
  final double borderRadius;

  /// WidgetOpenGraph constructor
  ///
  /// Required parameters:
  ///
  /// data: OpenGraphEntity data
  ///
  /// height: Height of the widget
  ///
  /// isProduction: Is production mode
  ///
  /// borderRadius: Border radius of the widget
  ///
  /// [WidgetOpenGraph] is a widget to show the OpenGraphEntity data
  /// [data] is the OpenGraphEntity data to show in the widget
  /// [height] is the height of the widget
  /// [isProduction] is a flag to show the image or a default image
  /// [borderRadius] is the border radius of the widget
  ///
  const WidgetOpenGraph({
    super.key,
    required this.data,
    required this.height,
    required this.isProduction,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          if (isProduction)
            data.image.isNotEmpty
                ? Image.network(data.image,
                    fit: BoxFit.fitWidth,
                    width: MediaQuery.of(context).size.width,
                    height: height)
                : Image.asset(
                    "assets/notfound.jpeg",
                    package: 'opengraph',
                    width: MediaQuery.of(context).size.width,
                    height: height,
                    fit: BoxFit.fitWidth,
                  ),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Padding(
              padding: EdgeInsets.all(borderRadius / 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.title != "")
                            Text(data.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          if (data.description != "")
                            Text(data.description,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          Text(Uri.parse(data.url).host,
                              style: const TextStyle(color: Colors.white54)),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
