import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';

/// Clase limpiada sin datos falsos ni listas estáticas hardcodeadas.
/// Toda la información operativa (autobuses, estudiantes, rutas, paradas y notificaciones)
/// proviene directamente de Supabase.
class MockData {
  MockData._();

  /// Delega el cálculo de ETA a [AppConstants.calculateEtaMinutes].
  static int calculateEtaMinutes({
    required double distanceKm,
    required int speedKmH,
  }) {
    return AppConstants.calculateEtaMinutes(
      distanceKm: distanceKm,
      speedKmH: speedKmH,
    );
  }
}
