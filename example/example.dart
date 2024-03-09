import 'package:flutter/material.dart';
import 'package:opengraph/opengraph.dart';

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