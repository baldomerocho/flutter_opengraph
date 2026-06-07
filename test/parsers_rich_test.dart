import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as parser;
import 'package:opengraph/opengraph.dart';

void main() {
  group('OpengraphParser structured objects', () {
    test('groups multiple og:image objects with their sub-properties', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image" content="https://example.com/a.png">
          <meta property="og:image:width" content="1200">
          <meta property="og:image:height" content="630">
          <meta property="og:image:secure_url" content="https://secure.example.com/a.png">
          <meta property="og:image:alt" content="First image">
          <meta property="og:image" content="https://example.com/b.png">
          <meta property="og:image:width" content="800">
        </head></html>
      ''');

      final images = OpengraphParser(document).images;

      expect(images.length, 2);
      expect(images[0].url, 'https://example.com/a.png');
      expect(images[0].width, 1200);
      expect(images[0].height, 630);
      expect(images[0].secureUrl, 'https://secure.example.com/a.png');
      expect(images[0].alt, 'First image');
      expect(images[1].url, 'https://example.com/b.png');
      expect(images[1].width, 800);
      expect(images[1].height, isNull);
    });

    test('og:image:url confirms the open object instead of duplicating', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image" content="https://example.com/a.png">
          <meta property="og:image:url" content="https://example.com/a.png">
          <meta property="og:image:width" content="100">
        </head></html>
      ''');

      final images = OpengraphParser(document).images;

      expect(images.length, 1);
      expect(images.single.url, 'https://example.com/a.png');
      expect(images.single.width, 100);
    });

    test('og:image:url alone opens an object', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image:url" content="https://example.com/only.png">
        </head></html>
      ''');

      expect(OpengraphParser(document).images.single.url,
          'https://example.com/only.png');
    });

    test('discards orphan sub-properties that appear before any root', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image:width" content="1200">
          <meta property="og:image" content="https://example.com/real.png">
        </head></html>
      ''');

      final images = OpengraphParser(document).images;

      expect(images.single.url, 'https://example.com/real.png');
      // The orphan width belonged to no object, so it is dropped.
      expect(images.single.width, isNull);
    });

    test('ignores tags with empty content', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image" content="">
          <meta property="og:image:width" content="999">
          <meta property="og:image" content="https://example.com/real.png">
        </head></html>
      ''');

      final images = OpengraphParser(document).images;

      expect(images.length, 1);
      expect(images.single.url, 'https://example.com/real.png');
      expect(images.single.width, isNull);
    });

    test('parses og:video and og:audio objects', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:video" content="https://example.com/v.mp4">
          <meta property="og:video:type" content="video/mp4">
          <meta property="og:video:width" content="1280">
          <meta property="og:video:height" content="720">
          <meta property="og:audio" content="https://example.com/a.mp3">
          <meta property="og:audio:type" content="audio/mpeg">
        </head></html>
      ''');

      final ogParser = OpengraphParser(document);

      expect(ogParser.videos.single.url, 'https://example.com/v.mp4');
      expect(ogParser.videos.single.type, 'video/mp4');
      expect(ogParser.videos.single.width, 1280);
      expect(ogParser.videos.single.height, 720);
      expect(ogParser.audios.single.url, 'https://example.com/a.mp3');
      expect(ogParser.audios.single.type, 'audio/mpeg');
    });

    test('accumulates repeated vertical tags in document order', () {
      final document = parser.parse('''
        <html><head>
          <meta property="article:author" content="https://example.com/author">
          <meta property="article:tag" content="flutter">
          <meta property="article:tag" content="opengraph">
          <meta property="book:isbn" content="978-3-16-148410-0">
        </head></html>
      ''');

      final tags = OpengraphParser(document).structuredTags;

      expect(tags['article:author'], ['https://example.com/author']);
      expect(tags['article:tag'], ['flutter', 'opengraph']);
      expect(tags['book:isbn'], ['978-3-16-148410-0']);
    });

    test('parse() carries the rich fields into the metadata', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:title" content="T">
          <meta property="og:image" content="https://example.com/a.png">
          <meta property="article:tag" content="flutter">
        </head></html>
      ''');

      final metadata = OpengraphParser(document).parse();

      expect(metadata.images.single.url, 'https://example.com/a.png');
      expect(metadata.structuredTags['article:tag'], ['flutter']);
    });
  });

  group('OpengraphMetadataParser rich merge', () {
    test('resolves relative urls of every structured object', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image" content="/img/a.png">
          <meta property="og:image:secure_url" content="/img/a-secure.png">
          <meta property="og:video" content="/v.mp4">
          <meta property="og:audio" content="/a.mp3">
        </head></html>
      ''');

      final metadata = OpengraphMetadataParser.parse(document,
          url: 'https://example.com/article');

      expect(metadata.images.single.url, 'https://example.com/img/a.png');
      expect(metadata.images.single.secureUrl,
          'https://example.com/img/a-secure.png');
      expect(metadata.videos.single.url, 'https://example.com/v.mp4');
      expect(metadata.audios.single.url, 'https://example.com/a.mp3');
    });

    test('og:image:url-only pages backfill the scalar image (not favicon)', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image:url" content="/structured.png">
          <link rel="icon" href="/favicon.ico">
        </head></html>
      ''');

      final metadata =
          OpengraphMetadataParser.parse(document, url: 'https://example.com');

      // The structured image wins over the favicon fallback.
      expect(metadata.image, 'https://example.com/structured.png');
      expect(metadata.faviconUrl, 'https://example.com/favicon.ico');
    });

    test('synthesizes images from a non-OG image so images.first works', () {
      final document = parser.parse('''
        <html><head>
          <meta name="twitter:image" content="https://example.com/tw.png">
        </head></html>
      ''');

      final metadata =
          OpengraphMetadataParser.parse(document, url: 'https://example.com');

      expect(metadata.image, 'https://example.com/tw.png');
      expect(metadata.images.single.url, 'https://example.com/tw.png');
    });
  });

  group('FaviconParser', () {
    test('reads link rel icon and shortcut icon', () {
      final document = parser.parse('''
        <html><head>
          <link rel="shortcut icon" href="/favicon.ico">
        </head></html>
      ''');

      expect(FaviconParser(document).faviconUrl, '/favicon.ico');
    });

    test('prefers apple-touch-icon over the generic icon', () {
      final document = parser.parse('''
        <html><head>
          <link rel="icon" href="/favicon-16.png">
          <link rel="apple-touch-icon" href="/touch-180.png">
        </head></html>
      ''');

      expect(FaviconParser(document).faviconUrl, '/touch-180.png');
    });

    test('returns null when the page declares no icon', () {
      final document = parser.parse('<html><head></head></html>');

      expect(FaviconParser(document).faviconUrl, isNull);
    });

    test('toString shows the parsed favicon', () {
      final document = parser
          .parse('<html><head><link rel="icon" href="/f.ico"></head></html>');

      expect(FaviconParser(document).toString(),
          'FaviconParser(faviconUrl: /f.ico)');
    });

    test('is used as last-resort image and resolved absolute', () {
      final document = parser.parse('''
        <html><head>
          <title>No images here</title>
          <link rel="icon" href="/favicon.ico">
        </head></html>
      ''');

      final metadata =
          OpengraphMetadataParser.parse(document, url: 'https://example.com');

      expect(metadata.faviconUrl, 'https://example.com/favicon.ico');
      expect(metadata.image, 'https://example.com/favicon.ico');
    });

    test('is exposed without overriding an existing image', () {
      final document = parser.parse('''
        <html><head>
          <meta property="og:image" content="https://example.com/og.png">
          <link rel="icon" href="/favicon.ico">
        </head></html>
      ''');

      final metadata =
          OpengraphMetadataParser.parse(document, url: 'https://example.com');

      expect(metadata.image, 'https://example.com/og.png');
      expect(metadata.faviconUrl, 'https://example.com/favicon.ico');
    });
  });

  group('JsonLdParser @graph and multiple scripts', () {
    test('traverses @graph and prefers a known node type', () {
      final document = parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@context": "https://schema.org", "@graph": [
              {"@type": "BreadcrumbList", "name": "crumbs"},
              {"@type": "NewsArticle", "headline": "Graph headline",
               "description": "Graph description"}
            ]}
          </script>
        </head></html>
      ''');

      final jsonLd = JsonLdParser(document);

      expect(jsonLd.title, 'Graph headline');
      expect(jsonLd.description, 'Graph description');
      expect(jsonLd.type, 'NewsArticle');
    });

    test(
        'prefers an Article in a later script over a standalone non-preferred '
        'node in the first one', () {
      // Yoast/WordPress-style markup: one ld+json script per entity.
      final document = parser.parse('''
        <html><head>
          <script type="application/ld+json">
            {"@type": "BreadcrumbList", "itemListElement": []}
          </script>
          <script type="application/ld+json">
            {"@type": "NewsArticle", "headline": "The real article",
             "description": "Real description"}
          </script>
        </head></html>
      ''');

      final jsonLd = JsonLdParser(document);

      expect(jsonLd.title, 'The real article');
      expect(jsonLd.type, 'NewsArticle');
    });

    test('skips scripts with invalid json and keeps looking', () {
      final document = parser.parse('''
        <html><head>
          <script type="application/ld+json">{not valid json</script>
          <script type="application/ld+json">
            {"@type": "Article", "name": "Second script"}
          </script>
        </head></html>
      ''');

      expect(JsonLdParser(document).title, 'Second script');
    });

    test('finds ld+json scripts in the body too', () {
      final document = parser.parse('''
        <html><head></head><body>
          <script type="application/ld+json">
            {"@type": "Product", "name": "Body product"}
          </script>
        </body></html>
      ''');

      expect(JsonLdParser(document).title, 'Body product');
    });

    test('falls back to the first map when no node type is preferred', () {
      final document = parser.parse('''
        <html><head>
          <script type="application/ld+json">
            [{"@type": "Thing", "name": "generic"},
             {"@type": "OtherThing", "name": "second"}]
          </script>
        </head></html>
      ''');

      expect(JsonLdParser(document).title, 'generic');
    });

    test('handles @type declared as a list', () {
      final document = parser.parse('''
        <html><head>
          <script type="application/ld+json">
            [{"@type": "Thing", "name": "generic"},
             {"@type": ["Article", "CreativeWork"], "name": "typed"}]
          </script>
        </head></html>
      ''');

      expect(JsonLdParser(document).title, 'typed');
    });
  });
}
