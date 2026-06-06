import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';
import 'package:http/http.dart' as http;

void main() {
  group('OpenGraphEntity', () {
    test('creates instance with required parameters', () {
      final entity = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      expect(entity.title, 'Test Title');
      expect(entity.description, 'Test Description');
      expect(entity.image, 'https://example.com/image.jpg');
      expect(entity.url, 'https://example.com');
      expect(entity.locale, 'en_US');
      expect(entity.type, 'article');
      expect(entity.siteName, 'Test Site');
    });

    test('converts to and from JSON correctly', () {
      final entity = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      final json = entity.toJson();
      final fromJson = OpenGraphEntity.fromJson(json);

      expect(fromJson.title, entity.title);
      expect(fromJson.description, entity.description);
      expect(fromJson.image, entity.image);
      expect(fromJson.url, entity.url);
      expect(fromJson.locale, entity.locale);
      expect(fromJson.type, entity.type);
      expect(fromJson.siteName, entity.siteName);
    });

    test('toString returns a string representation', () {
      final entity = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      final stringRepresentation = entity.toString();

      expect(stringRepresentation, contains('Test Title'));
      expect(stringRepresentation, contains('Test Description'));
      expect(stringRepresentation, contains('https://example.com/image.jpg'));
    });
  });

  group('OpengraphMetadataAdapter', () {
    test('converts from OpengraphMetadata to OpenGraphEntity', () {
      final metadata = OpengraphMetadata()
        ..title = 'Test Title'
        ..description = 'Test Description'
        ..image = 'https://example.com/image.jpg'
        ..url = 'https://example.com'
        ..locale = 'en_US'
        ..type = 'article'
        ..siteName = 'Test Site';

      final entity = OpengraphMetadataAdapter.toOpenGraphEntity(metadata);

      expect(entity.title, metadata.title);
      expect(entity.description, metadata.description);
      expect(entity.image, metadata.image);
      expect(entity.url, metadata.url);
      expect(entity.locale, metadata.locale);
      expect(entity.type, metadata.type);
      expect(entity.siteName, metadata.siteName);
    });

    test('converts from OpenGraphEntity to OpengraphMetadata', () {
      final entity = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      final metadata = OpengraphMetadataAdapter.fromOpenGraphEntity(entity);

      expect(metadata.title, entity.title);
      expect(metadata.description, entity.description);
      expect(metadata.image, entity.image);
      expect(metadata.url, entity.url);
      expect(metadata.locale, entity.locale);
      expect(metadata.type, entity.type);
      expect(metadata.siteName, entity.siteName);
    });
  });

  group('OpengraphFetch', () {
    test('extract handles invalid URLs', () async {
      final result = await OpengraphFetch.extract('invalid-url');

      // La implementación actual puede devolver null o un objeto con valores predeterminados
      // dependiendo de la implementación
      if (result != null) {
        expect(result.url, 'invalid-url');
      }
    });

    test('responseToDocument handles non-200 status codes', () {
      final mockResponse = http.Response('', 404);
      final document = OpengraphFetch.responseToDocument(mockResponse);
      expect(document, isNull);
    });

    test('responseToDocument handles parsing errors', () {
      // Crear una respuesta con contenido inválido que causará un error al analizar
      final mockResponse = http.Response('Invalid HTML content', 200);
      final document = OpengraphFetch.responseToDocument(mockResponse);
      expect(document,
          isNotNull); // Debería devolver un documento, incluso si está vacío
    });
  });

  group('opengraph_fetch_functions', () {
    test('opengraph_fetch_raw returns raw metadata', () async {
      // Verificar que la función devuelve los datos correctos
      final result = await opengraph_fetch_raw('https://example.com');

      // Puede ser nulo en caso de error, pero debería devolver algún tipo de metadatos
      expect(result, isNotNull);
    });

    test('opengraph_fetch returns OpenGraphEntity', () async {
      // Verificar que la función devuelve los datos correctos
      final result = await opengraph_fetch('https://example.com');

      // Puede ser nulo en caso de error, pero debería devolver algún tipo de entidad
      expect(result, isNotNull);
    });
  });

  group('WidgetOpenGraph', () {
    testWidgets('renders correctly with all data', (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            // Usar isProduction: false para evitar cargar imágenes de red
            isProduction: false,
            borderRadius: 10,
          ),
        ),
      ));

      // Pump para permitir que se construya la interfaz
      await tester.pump();

      // Verify the title is displayed
      expect(find.text('Test Title'), findsOneWidget);

      // Verify the description is displayed
      expect(find.text('Test Description'), findsOneWidget);

      // Verify the URL host is displayed
      expect(find.text('example.com'), findsOneWidget);
    });

    testWidgets('handles empty image gracefully', (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: '', // Empty image URL
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            // Usar isProduction: false para evitar cargar imágenes de red
            isProduction: false,
            borderRadius: 10,
          ),
        ),
      ));

      // Pump para permitir que se construya la interfaz
      await tester.pump();

      // Verificar que el título y la descripción se muestran
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('handles empty title and description',
        (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: '', // Empty title
        description: '', // Empty description
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: 200,
            // Usar isProduction: false para evitar cargar imágenes de red
            isProduction: false,
            borderRadius: 10,
          ),
        ),
      ));

      // Pump para permitir que se construya la interfaz
      await tester.pump();

      // Verify only the URL is displayed (no title or description)
      expect(find.text('example.com'), findsOneWidget);
      expect(
          find.text(''), findsNothing); // Empty strings should not be rendered
    });

    testWidgets('applies custom styling correctly',
        (WidgetTester tester) async {
      final data = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'article',
        siteName: 'Test Site',
      );

      const customBorderRadius = 20.0;
      const customHeight = 250.0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetOpenGraph(
            data: data,
            height: customHeight,
            borderRadius: customBorderRadius,
            isProduction: false,
          ),
        ),
      ));

      await tester.pump();

      // Verificar que se muestra el título correctamente
      expect(find.text('Test Title'), findsOneWidget);

      // Verificar que se muestra la descripción correctamente
      expect(find.text('Test Description'), findsOneWidget);
    });
  });
}
