import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/widgets/trust_safety_dialog.dart';

void main() {
  testWidgets('TrustSafetyDialog renderiza elementos de auditoría y distintivos de seguridad', (WidgetTester tester) async {
    final bus = BusMock(
      id: 1,
      code: 'BUS-01',
      plate: 'TBX-492',
      model: 'Toyota Coaster Escolar',
      capacity: 16,
      seatsOccupied: 14,
      status: 'En recorrido',
      driverName: 'Carlos Gómez',
      ownerName: 'Transportes Escolar',
      simulatedGpsActive: true,
      isVerified: true,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<BusService>(create: (_) => BusService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TrustSafetyDialog.show(context, bus: bus, isOwnerView: true);
                },
                child: const Text('Abrir Sello'),
              ),
            ),
          ),
        ),
      ),
    );

    // Abrir diálogo
    await tester.tap(find.text('Abrir Sello'));
    await tester.pumpAndSettle();

    // Validar que se muestre el encabezado y distintivos
    expect(find.text('Sello de Confianza Escolar'), findsOneWidget);
    expect(find.text('CERTIFICADO'), findsOneWidget);
    expect(find.textContaining('TBX-492'), findsOneWidget);
    expect(find.textContaining('Carlos Gómez'), findsOneWidget);

    // Validar los 4 ítems de auditoría obligatorios (RF-03, RNF-12)
    expect(find.text('Récord Policivo y Antecedentes Penales'), findsOneWidget);
    expect(find.text('Licencia Comercial de Conducción'), findsOneWidget);
    expect(find.text('Póliza de Seguros Todo Riesgo Escolar'), findsOneWidget);
    expect(find.text('Revisión Técnico-Mecánica (RTM)'), findsOneWidget);

    // Validar botón de suspensión/aprobación para transportista
    expect(find.text('Suspender Sello de Confianza'), findsOneWidget);
  });
}
