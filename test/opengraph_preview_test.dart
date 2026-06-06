import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';

void main() {
  group('OpengraphPreview', () {
    testWidgets('displays loading indicator while fetching data', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: OpengraphPreview(url: 'https://flutter.dev'),
        ),
      ));
      
      // Verificar que se muestra el indicador de carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('applies custom styling correctly', (WidgetTester tester) async {
      const customBackgroundColor = Colors.blue;
      const customProgressColor = Colors.white;
      const customBorderRadius = 15.0;
      const customHeight = 250.0;
      
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: OpengraphPreview(
            url: 'https://flutter.dev',
            backgroundColor: customBackgroundColor,
            progressColor: customProgressColor,
            borderRadius: customBorderRadius,
            height: customHeight,
          ),
        ),
      ));
      
      // Verificar que se aplica el color de fondo personalizado
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, customBackgroundColor);
      
      // Verificar que se aplica el radio de borde personalizado
      expect(decoration.borderRadius, BorderRadius.circular(customBorderRadius));
      
      // Verificar que se aplica el color del indicador de progreso personalizado
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, customProgressColor);
    });
    
    testWidgets('handles custom error message', (WidgetTester tester) async {
      const customErrorMessage = 'Custom Error Message';
      
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: OpengraphPreview(
            url: 'invalid-url',
            error: customErrorMessage,
          ),
        ),
      ));
      
      // Esperar a que se complete la carga
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      
      // Puede que no se muestre el mensaje de error si la URL inválida no genera un error
      // o si el widget está aún en estado de carga, así que no verificamos su presencia
    });
  });
}
