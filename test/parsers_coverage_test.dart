import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html;
import 'package:opengraph/opengraph.dart';

void main() {
  group('JsonLdParser with a JSON-LD array payload', () {
    final document = html.parse('''
      <html><head>
        <script type="application/ld+json">
          [{
            "name": "List Name",
            "description": "List Description",
            "image": ["https://example.com/first.png", "https://example.com/second.png"],
            "url": "https://example.com/article",
            "@type": "Article",
            "publisher": {"name": "List Publisher"}
          }]
        </script>
      </head><body></body></html>
    ''');

    test('reads fields from the first element of the list', () {
      final parser = JsonLdParser(document);

      expect(parser.title, 'List Name');
      expect(parser.description, 'List Description');
      expect(parser.url, 'https://example.com/article');
      expect(parser.type, 'Article');
      expect(parser.siteName, 'List Publisher');
    });

    test('takes the first image when image is a list', () {
      expect(JsonLdParser(document).image, 'https://example.com/first.png');
    });
  });

  group('JsonLdParser with a JSON-LD object payload', () {
    final document = html.parse('''
      <html><head>
        <script type="application/ld+json">
          {
            "headline": "Object Headline",
            "logo": "https://example.com/logo.png",
            "publisher": "not-a-map"
          }
        </script>
      </head><body></body></html>
    ''');

    test('falls back to headline and reads logo', () {
      final parser = JsonLdParser(document);

      expect(parser.title, 'Object Headline');
      expect(parser.description, 'Object Headline');
      expect(parser.image, 'https://example.com/logo.png');
      expect(parser.type, 'website');
      // publisher that is not a map yields no site name
      expect(parser.siteName, isNull);
    });
  });

  group('parsers toString', () {
    final document = html.parse('''
      <html><head>
        <title>Doc Title</title>
        <meta property="og:title" content="OG Title">
        <meta name="twitter:title" content="TW Title">
      </head><body></body></html>
    ''');

    test('every parser renders its parsed metadata', () {
      expect(OpengraphParser(document).toString(), contains('OG Title'));
      expect(TwitterCardParser(document).toString(), contains('TW Title'));
      expect(HtmlMetaParser(document).toString(), contains('Doc Title'));
      expect(JsonLdParser(document).toString(), contains('title'));
    });

    test('OpengraphMetadata toString matches its map', () {
      final metadata = OpengraphMetadata();
      metadata.title = 'A title';

      expect(metadata.toString(), metadata.toMap().toString());
    });
  });
}
