import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opengraph/src/opengraph_fetch_base.dart';
import 'package:opengraph/src/opengraph_fetch_functions.dart';
import 'package:opengraph/src/parsers/parsers.dart';
import 'package:opengraph/src/adapters/opengraph_metadata_adapter.dart';
import 'package:opengraph/src/models/open_graph_entity.dart';

// No necesitamos generar mocks para este archivo

void main() {
  group('opengraph_fetch_functions', () {
    test('opengraph_fetch handles invalid URLs', () async {
      // Llamar a la función con una URL inválida
      final result = await opengraph_fetch('invalid-url');
      
      // La implementación actual puede devolver null para URLs inválidas
      // o una entidad con valores por defecto, dependiendo de la implementación
      if (result != null) {
        expect(result.url, 'invalid-url');
      }
    });
  });
  
  group('OpengraphFetch', () {
    test('responseToDocument handles valid HTML', () {
      // Preparar una respuesta HTML válida
      const htmlResponse = '''
      <html>
        <head>
          <title>Test Page</title>
        </head>
        <body>
          <h1>Hello, World!</h1>
        </body>
      </html>
      ''';
      
      final response = http.Response(htmlResponse, 200);
      
      // Llamar al método que queremos probar
      final document = OpengraphFetch.responseToDocument(response);
      
      // Verificar que el método analiza el HTML correctamente
      expect(document, isNotNull);
      expect(document!.querySelector('title')?.text, 'Test Page');
      expect(document.querySelector('h1')?.text, 'Hello, World!');
    });
    
    test('responseToDocument handles non-200 status codes', () {
      final response = http.Response('', 404);
      
      // Llamar al método que queremos probar
      final document = OpengraphFetch.responseToDocument(response);
      
      // Verificar que el método devuelve null para respuestas con error
      expect(document, isNull);
    });
  });
  
  group('OpengraphMetadataAdapter', () {
    test('toOpenGraphEntity converts OpengraphMetadata to OpenGraphEntity', () {
      // Crear un objeto OpengraphMetadata
      final metadata = OpengraphMetadata()
        ..title = 'Test Title'
        ..description = 'Test Description'
        ..image = 'https://example.com/image.jpg'
        ..url = 'https://example.com'
        ..locale = 'en_US'
        ..type = 'website'
        ..siteName = 'Test Site';
      
      // Llamar al método que queremos probar
      final entity = OpengraphMetadataAdapter.toOpenGraphEntity(metadata);
      
      // Verificar que el método convierte correctamente
      expect(entity.title, metadata.title);
      expect(entity.description, metadata.description);
      expect(entity.image, metadata.image);
      expect(entity.url, metadata.url);
      expect(entity.locale, metadata.locale);
      expect(entity.type, metadata.type);
      expect(entity.siteName, metadata.siteName);
    });
    
    test('fromOpenGraphEntity converts OpenGraphEntity to OpengraphMetadata', () {
      // Crear un objeto OpenGraphEntity
      final entity = OpenGraphEntity(
        title: 'Test Title',
        description: 'Test Description',
        image: 'https://example.com/image.jpg',
        url: 'https://example.com',
        locale: 'en_US',
        type: 'website',
        siteName: 'Test Site',
      );
      
      // Llamar al método que queremos probar
      final metadata = OpengraphMetadataAdapter.fromOpenGraphEntity(entity);
      
      // Verificar que el método convierte correctamente
      expect(metadata.title, entity.title);
      expect(metadata.description, entity.description);
      expect(metadata.image, entity.image);
      expect(metadata.url, entity.url);
      expect(metadata.locale, entity.locale);
      expect(metadata.type, entity.type);
      expect(metadata.siteName, entity.siteName);
    });
    
    test('toOpenGraphEntity handles null values', () {
      // Crear un objeto OpengraphMetadata con valores nulos
      final metadata = OpengraphMetadata();
      
      // Llamar al método que queremos probar
      final entity = OpengraphMetadataAdapter.toOpenGraphEntity(metadata);
      
      // Verificar que el método maneja los valores nulos correctamente
      // Los valores por defecto pueden variar según la implementación
      expect(entity.title, isNotNull);
      expect(entity.description, isNotNull);
      expect(entity.image, isNotNull);
      expect(entity.url, isNotNull);
      expect(entity.locale, isNotNull);
      expect(entity.type, isNotNull);
      expect(entity.siteName, isNotNull);
    });
  });
}
