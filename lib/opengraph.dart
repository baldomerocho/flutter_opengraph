library opengraph;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:opengraph/entities/open_graph_entity.dart';

import 'fetch_opengraph.dart';

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
      });

  @override
  State<OpenGraphPreview> createState() => _OpenGraphPreviewState();
}

class _OpenGraphPreviewState extends State<OpenGraphPreview> {

  @override
  Widget build(BuildContext context) {
    final provider = OpenGraphRequest();
    future(){
      return provider.fetch(widget.url);
    }

    return Container(
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
                  child: Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(widget.progressColor),
                  ))
              );
            }

            if (snapshot.hasError) {
              return Container(
                  height: widget.height,
                  color: widget.backgroundColor,
                  child: Center(child: Text(widget.error))
              );
            }

            final data = snapshot.data as OpenGraphEntity;
            return SizedBox(
              height: widget.height,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  if(data.image != "") Container(
                    decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(data.image), fit: BoxFit.cover)),
                  ),
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: Padding(
                      padding: EdgeInsets.all(widget.borderRadius/2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.borderRadius/2),
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
                                  if(data.title!="")Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if(data.description!="")Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  Text(Uri.parse(data.url).host, style: const TextStyle(color: Colors.white54)),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: widget.showReloadButton,
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
                                child: Text(widget.preview, style: const TextStyle(color: Colors.white)),
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
                                  onTap: () => setState(() {}),
                                  child: Text(widget.refresh, style: const TextStyle(color: Colors.white))),
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

