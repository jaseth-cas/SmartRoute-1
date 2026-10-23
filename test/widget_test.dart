import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/main.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';

void main() {
  testWidgets('SmartRouteApp smoke test inicialización limpia', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SessionManager()),
        ],
        child: const SmartRouteApp(),
      ),
    );

    // Esperar que construya el frame inicial
    await tester.pump();

    // Comprobar que el título SmartRoute aparece en pantalla
    expect(find.text('SmartRoute'), findsWidgets);
  });
}
