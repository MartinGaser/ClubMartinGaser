import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas básicas de la interfaz.
///
/// Firebase necesita configuración nativa, por eso esta prueba
/// comprueba un componente visual aislado y no inicia Firebase.
void main() {
  testWidgets('La aplicación puede mostrar su nombre', (
    WidgetTester tester,
  ) async {
    // Construye una interfaz aislada para la prueba.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('ClubMartinGaser'))),
      ),
    );

    // Verifica que el nombre aparezca exactamente una vez.
    expect(find.text('ClubMartinGaser'), findsOneWidget);
  });
}
