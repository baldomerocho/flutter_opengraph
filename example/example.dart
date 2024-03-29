// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:opengraph/opengraph.dart';

class OpenGraphProvider {
  static OpenGraphConfiguration CONFIG =
      OpenGraphConfiguration(maxObjects: 1000);
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the provider
  OpenGraphRequest().initProvider(OpenGraphProvider.CONFIG);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('OpenGraph Preview'),
        ),
        body: const Center(
          child: OpenGraphPreview(
            url: "https://www.youtube.com/watch?v=6g4dkBF5anU",
          ),
        ),
      ),
    );
  }
}
