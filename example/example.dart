import 'package:flutter/material.dart';
import 'package:opengraph/opengraph.dart';

class OpenGraphProvider {
  static OpenGraphConfiguration CONFIG = OpenGraphConfiguration(
      maxObjects: 1000);
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
