import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';

/// 1x1 transparent PNG
const String _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

OpenGraphEntity _entity({required String image}) {
  return OpenGraphEntity(
    title: 'Title',
    description: 'Description',
    image: image,
    url: 'https://example.com',
    locale: 'en_US',
    type: 'website',
    siteName: 'Example',
  );
}

Widget _wrap(OpenGraphEntity data) {
  return MaterialApp(
    home: Scaffold(
      body: WidgetOpenGraph(
        data: data,
        height: 200,
        isProduction: true,
        borderRadius: 10,
      ),
    ),
  );
}

void main() {
  group('WidgetOpenGraph image handling', () {
    testWidgets('renders base64 data: URI images with Image.memory',
        (WidgetTester tester) async {
      const dataUri = 'data:image/png;base64,$_tinyPngBase64';

      await tester.pumpWidget(_wrap(_entity(image: dataUri)));
      await tester.pump();

      // Must not throw "No host specified in URI data:image/..."
      expect(tester.takeException(), isNull);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());
    });

    testWidgets('malformed data: URI falls back to the default image',
        (WidgetTester tester) async {
      const malformed = 'data:image/png;base64,@@not-valid-base64@@';

      await tester.pumpWidget(_wrap(_entity(image: malformed)));
      await tester.pump();

      expect(tester.takeException(), isNull);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
    });

    testWidgets('data: URI without payload falls back to the default image',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(_entity(image: 'data:')));
      await tester.pump();

      expect(tester.takeException(), isNull);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
    });

    testWidgets('empty image uses the default image',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(_entity(image: '')));
      await tester.pump();

      expect(tester.takeException(), isNull);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
    });

    testWidgets('network images keep using Image.network',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(_wrap(_entity(image: 'https://example.com/image.png')));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
      // A broken network image must not crash the widget: the errorBuilder
      // swaps in the fallback. (flutter_test's HttpClient always returns 400.)
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
