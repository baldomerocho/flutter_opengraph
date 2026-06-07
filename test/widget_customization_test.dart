import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';

OpenGraphEntity _entity({String image = ''}) {
  return OpenGraphEntity(
    title: 'Custom title',
    description: 'Custom description',
    image: image,
    url: 'https://example.com',
    locale: 'en_US',
    type: 'website',
    siteName: 'Example',
  );
}

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

WidgetOpenGraph _card({
  TextStyle? titleStyle,
  TextStyle? descriptionStyle,
  TextStyle? hostStyle,
  int titleMaxLines = 1,
  int descriptionMaxLines = 2,
  Color overlayColor = const Color(0x80000000),
  BoxFit imageFit = BoxFit.fitWidth,
  VoidCallback? onTap,
  OpenGraphLayout layout = OpenGraphLayout.overlay,
}) {
  return WidgetOpenGraph(
    data: _entity(),
    height: 200,
    isProduction: true,
    borderRadius: 10,
    titleStyle: titleStyle,
    descriptionStyle: descriptionStyle,
    hostStyle: hostStyle,
    titleMaxLines: titleMaxLines,
    descriptionMaxLines: descriptionMaxLines,
    overlayColor: overlayColor,
    imageFit: imageFit,
    onTap: onTap,
    layout: layout,
  );
}

void main() {
  setUp(OpengraphCache.clear);

  group('WidgetOpenGraph customization', () {
    testWidgets('titleStyle merges over the default (bold preserved)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          _app(_card(titleStyle: const TextStyle(color: Colors.amber))));

      final title = tester.widget<Text>(find.text('Custom title'));
      expect(title.style!.color, Colors.amber);
      // The default bold weight survives the merge.
      expect(title.style!.fontWeight, FontWeight.bold);
    });

    testWidgets('descriptionStyle and hostStyle are applied',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_card(
        descriptionStyle: const TextStyle(fontSize: 11),
        hostStyle: const TextStyle(color: Colors.teal),
      )));

      final description = tester.widget<Text>(find.text('Custom description'));
      final host = tester.widget<Text>(find.text('example.com'));
      expect(description.style!.fontSize, 11);
      expect(description.style!.color, Colors.white); // default preserved
      expect(host.style!.color, Colors.teal);
    });

    testWidgets('maxLines are forwarded', (WidgetTester tester) async {
      await tester
          .pumpWidget(_app(_card(titleMaxLines: 3, descriptionMaxLines: 5)));

      expect(tester.widget<Text>(find.text('Custom title')).maxLines, 3);
      expect(tester.widget<Text>(find.text('Custom description')).maxLines, 5);
    });

    testWidgets('overlayColor replaces the default panel color',
        (WidgetTester tester) async {
      const custom = Color(0xCC112233);
      await tester.pumpWidget(_app(_card(overlayColor: custom)));

      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.any((c) => c.color == custom), isTrue);
    });

    testWidgets('imageFit is forwarded to the image',
        (WidgetTester tester) async {
      // Empty image -> bundled fallback asset, which also honors imageFit.
      await tester.pumpWidget(_app(_card(imageFit: BoxFit.cover)));

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('onTap makes the card tappable', (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(_card(onTap: () => taps++)));

      await tester.tap(find.byType(WidgetOpenGraph));
      expect(taps, 1);
    });

    testWidgets('without onTap there is no gesture detector',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_card()));

      expect(
          find.descendant(
              of: find.byType(WidgetOpenGraph),
              matching: find.byType(GestureDetector)),
          findsNothing);
    });

    testWidgets('horizontal layout shows a side image and no overlay stack',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_card(layout: OpenGraphLayout.horizontal)));

      expect(
          find.descendant(
              of: find.byType(WidgetOpenGraph), matching: find.byType(Row)),
          findsOneWidget);
      // The image box is square: width == card height.
      final imageBox = tester.getSize(find
          .ancestor(of: find.byType(Image), matching: find.byType(SizedBox))
          .first);
      expect(imageBox.width, 200);
      expect(find.text('Custom title'), findsOneWidget);
    });

    testWidgets('horizontal layout without image still renders the texts',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(WidgetOpenGraph(
        data: _entity(),
        height: 200,
        isProduction: false,
        borderRadius: 10,
        layout: OpenGraphLayout.horizontal,
      )));

      expect(find.byType(Image), findsNothing);
      expect(find.byType(Row), findsOneWidget);
      expect(find.text('Custom title'), findsOneWidget);
      expect(find.text('Custom description'), findsOneWidget);
      expect(find.text('example.com'), findsOneWidget);
    });
  });

  group('OpengraphPreview forwards customization', () {
    testWidgets('styles, layout and onTap reach the rendered card',
        (WidgetTester tester) async {
      const url = 'https://cached.example.com';
      OpengraphCache.put(url, _entity());
      var taps = 0;

      await tester.pumpWidget(_app(OpengraphPreview(
        url: url,
        titleStyle: const TextStyle(color: Colors.amber),
        overlayColor: const Color(0xCC112233),
        imageFit: BoxFit.contain,
        layout: OpenGraphLayout.horizontal,
        onTap: () => taps++,
      )));
      await tester.pump();

      final card = tester.widget<WidgetOpenGraph>(find.byType(WidgetOpenGraph));
      expect(card.titleStyle!.color, Colors.amber);
      expect(card.overlayColor, const Color(0xCC112233));
      expect(card.imageFit, BoxFit.contain);
      expect(card.layout, OpenGraphLayout.horizontal);

      await tester.tap(find.byType(WidgetOpenGraph));
      expect(taps, 1);
    });
  });
}
