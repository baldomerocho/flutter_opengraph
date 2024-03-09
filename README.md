### OpenGraph Preview Widget

[![Crear Release](https://github.com/baldomerocho/flutter_opengraph/actions/workflows/release.yaml/badge.svg?branch=master)](https://github.com/baldomerocho/flutter_opengraph/actions/workflows/release.yaml)

This widget allows you to preview the OpenGraph data of a URL.

## Api Key
You can get an API key from [https://recursos.datogedon.com/product/opengraph-api-key/](https://recursos.datogedon.com/product/opengraph-api-key/) to use this package. Use the free plan.

## Getting Started
Initialize the widget with the URL you want to preview.


## Example
```dart
import 'package:flutter/material.dart';
import 'package:opengraph/fetch_opengraph.dart';

class OpenGraphProvider{
  static OpenGraphCredentials CONFIG = OpenGraphCredentials(
    url: "https://app.server.gt/api/opengraph/?site=",
    token: "<TOKEN>",
    maxObjects: 1000
  );
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the provider
  OpenGraphRequest().initProvider(OpenGraphProvider.CONFIG);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OpenGraph Preview'),
        ),
        body: Center(
          child: OpenGraphPreview(
            url: "https://www.youtube.com/watch?v=6g4dkBF5anU",
          ),
        ),
      ),
    );
  }
}
```

## Test Flutter Pad
You can test the package in the flutter pad [here](https://dartpad.dev/?id=948cf2b7634b3ba45d891680600d3029) with the following code: