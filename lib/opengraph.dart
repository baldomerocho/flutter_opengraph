library opengraph;

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:opengraph/entities/open_graph_entity.dart';

import 'fetch_opengraph.dart';

class OpenGraphPreview extends StatelessWidget {
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

  const OpenGraphPreview(
      {super.key,
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
      });

  @override
  Widget build(BuildContext context) {
    final provider = OpenGraphRequest();
    future(){
      return provider.fetch(url);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FutureBuilder(
          future: future(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                  height: height,
                  color: backgroundColor,
                  child: Center(child: CupertinoActivityIndicator(
                    color: progressColor,
                  ))
              );
            }

            if (snapshot.hasError && !snapshot.hasData && snapshot.data == null) {
              return Container(
                  height: height,
                  color: backgroundColor,
                  child: Center(child: Text(error, style: TextStyle(color: Colors.pink.shade200)))
              );
            }

            final data = snapshot.data as OpenGraphEntity;

            if(data.title == "" && data.description == "" && data.image == "") {
              return const SizedBox.shrink();
            }


            return SizedBox(
              height: height,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  if(data.image != "") Container(
                    decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(data.image), fit: BoxFit.cover)),
                  ),
                  if(data.image != "") childError,
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: Padding(
                      padding: EdgeInsets.all(borderRadius/2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius/2),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:[
                                  if(data.title!="")Text(data.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if(data.description!="")Text(data.description, style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  Text(Uri.parse(data.url).host, style: const TextStyle(color: Colors.white54)),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: showReloadButton,
                    child: Positioned(
                        right: 0.0,
                        top: 0.0,
                        left: 0.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Card(
                              color: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(preview, style: const TextStyle(color: Colors.white)),
                              )
                            ),
                            Card(
                              color: Colors.blue.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: GestureDetector(
                                  onTap: () => provider.fetch(url),
                                  child: Text(refresh, style: const TextStyle(color: Colors.white))),
                              ),
                            )
                          ],
                        ),
                      ),
                  )
                  ],
              ),
            );
          }
        ),
      ),
    );
  }
}

