import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/main.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/incident_service.dart';

void main() {
  testWidgets('SmartRouteApp smoke test inicialización limpia', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SessionManager()),
          Provider(create: (_) => AuthService()),
          Provider(create: (_) => BusService()),
          Provider(create: (_) => StudentService()),
          Provider(create: (_) => AttendanceService()),
          Provider(create: (_) => IncidentService()),
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
