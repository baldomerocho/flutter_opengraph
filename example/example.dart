import 'package:flutter/material.dart';
import 'package:opengraph/opengraph.dart';

// Example showing the preview widget, its customization options and the
// fetch functionality. No initialization is required: results are cached
// in memory automatically (see OpengraphCache to tune it).

void main() {
  // Optional tuning:
  // OpengraphCache.maxEntries = 500;
  // OpengraphFetch.timeout = const Duration(seconds: 5);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('OpenGraph Examples'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Basic Preview'),
                Tab(text: 'Custom Styling'),
                Tab(text: 'Options'),
                Tab(text: 'Fetch API'),
                Tab(text: 'Parsers'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Tab 1: Basic Preview Example
              const SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Basic OpenGraph Preview',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Example of using the OpengraphPreview widget with YouTube
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: OpengraphPreview(
                        url: "https://www.youtube.com/watch?v=6g4dkBF5anU",
                      ),
                    ),
                    Divider(),
                    // Example with a news article
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: OpengraphPreview(
                        url:
                            "https://www.theverge.com/2025/5/15/tech-news-flutter",
                      ),
                    ),
                    Divider(),
                    // Example with GitHub repository
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: OpengraphPreview(
                        url:
                            "https://github.com/baldomerocho/flutter_opengraph",
                      ),
                    ),
                  ],
                ),
              ),

              // Tab 2: Custom Styling Examples
              const SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Custom Styled Previews',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Example with custom styling - dark theme
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: OpengraphPreview(
                        url: "https://flutter.dev",
                        height: 200,
                        borderRadius: 16,
                        backgroundColor: Colors.black87,
                        progressColor: Colors.white54,
                      ),
                    ),
                    Divider(),
                    // Example with custom styling - rounded corners
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: OpengraphPreview(
                        url: "https://pub.dev/packages/opengraph",
                        height: 180,
                        borderRadius: 24,
                        backgroundColor: Color(0xFFE0F7FA),
                        progressColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab 3: Error, fallback and performance options (1.1.0+)
              ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Error, fallback and performance options',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('hideOnError: renders nothing if the URL '
                        'cannot be fetched (nothing shows below)'),
                  ),
                  const OpengraphPreview(
                    url: "https://this-domain-does-not-exist.example",
                    hideOnError: true,
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('childError: your own widget when the '
                        'fetch fails'),
                  ),
                  OpengraphPreview(
                    url: "https://this-domain-does-not-exist.example",
                    childError: Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Colors.red.shade50,
                      child: const ListTile(
                        leading: Icon(Icons.link_off, color: Colors.red),
                        title: Text('Could not load this link'),
                      ),
                    ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('showReloadButton: retry button that '
                        'invalidates the cache for that URL'),
                  ),
                  const OpengraphPreview(
                    url: "https://this-domain-does-not-exist.example",
                    showReloadButton: true,
                    refresh: "Try again",
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('fallbackImage: replaces the default image '
                        'when the page has no og:image'),
                  ),
                  OpengraphPreview(
                    url: "https://example.com",
                    fallbackImage: Container(
                      color: Colors.blueGrey,
                      child: const Center(
                        child:
                            Icon(Icons.public, size: 64, color: Colors.white70),
                      ),
                    ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Long lists: previews are cached and '
                        'fetched once; enableBlur: false avoids the '
                        'expensive BackdropFilter per item'),
                  ),
                  // In a real app this would be a ListView.builder as the
                  // only scrollable; previews are cached so scrolling back
                  // never refetches.
                  for (final url in const [
                    "https://flutter.dev",
                    "https://dart.dev",
                    "https://pub.dev/packages/opengraph",
                  ])
                    OpengraphPreview(
                      url: url,
                      height: 150,
                      enableBlur: false,
                    ),
                ],
              ),

              // Tab 4: Fetch API Examples
              SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'OpenGraph Fetch API',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Example of using the opengraph_fetch functionality
                    FutureBuilder(
                      future: opengraph_fetch(
                          "https://github.com/baldomerocho/flutter_opengraph"),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("Error fetching data"),
                          );
                        }
                        final data = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Title: ${data.title}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text("Description: ${data.description}"),
                                  const SizedBox(height: 8),
                                  Text("Type: ${data.type}"),
                                  Text("Site Name: ${data.siteName}"),
                                  const SizedBox(height: 8),
                                  if (data.image.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(data.image,
                                          height: 150),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Example of using the opengraph_fetch_raw functionality
                    ElevatedButton(
                      onPressed: () async {
                        final rawData =
                            await opengraph_fetch_raw("https://datogedon.com");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  "Raw data fetched: ${rawData?.title ?? 'No data'}")));
                        }
                      },
                      child: const Text("Fetch Raw OpenGraph Data"),
                    ),
                  ],
                ),
              ),

              // Tab 5: Parsers Examples
              SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Parser Examples',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // OpenGraph Parser Example
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('OpenGraph Parser',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Example with Facebook (og: tags)'),
                            const SizedBox(height: 8),
                            const OpengraphPreview(
                                url: "https://www.facebook.com/flutter.io"),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final data = await opengraph_fetch(
                                    "https://www.facebook.com/flutter.io");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Parser used: OpenGraph\nTitle: ${data?.title}")));
                                }
                              },
                              child: const Text("Show OpenGraph Data"),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Twitter Card Parser Example
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Twitter Card Parser',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Example with Twitter (twitter: tags)'),
                            const SizedBox(height: 8),
                            const OpengraphPreview(
                                url: "https://twitter.com/flutterdev"),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final data = await opengraph_fetch(
                                    "https://twitter.com/flutterdev");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Parser used: Twitter Card\nTitle: ${data?.title}")));
                                }
                              },
                              child: const Text("Show Twitter Card Data"),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // JSON-LD Parser Example
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('JSON-LD Parser',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text(
                                'Example with structured data (JSON-LD)'),
                            const SizedBox(height: 8),
                            const OpengraphPreview(
                                url: "https://schema.org/docs/schemas.html"),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final data = await opengraph_fetch(
                                    "https://schema.org/docs/schemas.html");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Parser used: JSON-LD\nTitle: ${data?.title}")));
                                }
                              },
                              child: const Text("Show JSON-LD Data"),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // HTML Meta Parser Example
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('HTML Meta Parser',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Example with standard HTML meta tags'),
                            const SizedBox(height: 8),
                            const OpengraphPreview(url: "https://dart.dev"),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final data =
                                    await opengraph_fetch("https://dart.dev");
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Parser used: HTML Meta\nTitle: ${data?.title}")));
                                }
                              },
                              child: const Text("Show HTML Meta Data"),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Parser Priority Explanation
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Colors.amber.shade100,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Parser Priority',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text(
                                'The opengraph_fetch function tries parsers in this order:'),
                            SizedBox(height: 4),
                            Text('1. OpenGraph Parser (og: tags)'),
                            Text('2. Twitter Card Parser (twitter: tags)'),
                            Text('3. JSON-LD Parser (structured data)'),
                            Text('4. HTML Meta Parser (standard meta tags)'),
                            SizedBox(height: 8),
                            Text(
                                'Each parser fills in missing data from the previous parsers.'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
