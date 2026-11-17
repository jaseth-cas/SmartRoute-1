import 'package:latlong2/latlong.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';

/// Constantes geográficas y operativas globales de SmartRoute (Penonomé, Coclé).
class AppConstants {
  AppConstants._();

  /// Centro geográfico de referencia en Penonomé, Coclé, Panamá (Parque 8 de Diciembre).
  static const LatLng penonomeCenter = LatLng(8.5186, -80.3572);

  /// Punto escolar de referencia por defecto (Colegio Ángel María Herrera).
  static const LatLng defaultSchoolPoint = LatLng(8.51122, -80.35509);

  /// Catálogo geográfico oficial de colegios de Penonomé en OpenStreetMap.
  static const List<SchoolLocation> penonomeSchools = [
    SchoolLocation(
      id: 'SCH-01',
      name: 'Colegio Ángel María Herrera',
      shortName: 'Ángel María Herrera',
      latitude: 8.51122,
      longitude: -80.35509,
      address: 'Av. Héctor Conte Bermúdez, Penonomé',
      type: 'Colegio Secundario Oficial',
      code: 'CAMH',
    ),
    SchoolLocation(
      id: 'SCH-02',
      name: 'Colegio San Agustín',
      shortName: 'San Agustín',
      latitude: 8.49523,
      longitude: -80.35386,
      address: 'Calle Padres Agustinos, Penonomé',
      type: 'Colegio Católico Particular',
      code: 'CSA',
    ),
    SchoolLocation(
      id: 'SCH-03',
      name: 'I.P.T. Leonila Pinzón de Grimaldo',
      shortName: 'IPT Leonila Pinzón',
      latitude: 8.51568,
      longitude: -80.34396,
      address: 'Vía Penonomé, Coclé',
      type: 'Instituto Profesional y Técnico',
      code: 'IPTLPG',
    ),
    SchoolLocation(
      id: 'SCH-04',
      name: 'C.E.B.G. Federico Zúñiga Feliú',
      shortName: 'Federico Zúñiga',
      latitude: 8.52152,
      longitude: -80.36546,
      address: 'Barrio San Antonio, Penonomé',
      type: 'Centro Educativo Básico General',
      code: 'FZF',
    ),
    SchoolLocation(
      id: 'SCH-05',
      name: 'Colegio San Ignacio de Loyola',
      shortName: 'San Ignacio de Loyola',
      latitude: 8.50207,
      longitude: -80.35253,
      address: 'Penonomé, Coclé',
      type: 'Colegio Particular',
      code: 'CSIL',
    ),
    SchoolLocation(
      id: 'SCH-06',
      name: 'Excelsior International School',
      shortName: 'Excelsior Int. School',
      latitude: 8.50663,
      longitude: -80.35106,
      address: 'Barriada Miraflores, Penonomé',
      type: 'Colegio Internacional Bilingüe',
      code: 'EIS',
    ),
    SchoolLocation(
      id: 'SCH-07',
      name: 'Centro Educativo Santo Domingo',
      shortName: 'Santo Domingo',
      latitude: 8.52304,
      longitude: -80.34723,
      address: 'Vía hacia Sonadora, Penonomé',
      type: 'Centro Educativo Primario',
      code: 'CESD',
    ),
    SchoolLocation(
      id: 'SCH-08',
      name: 'Escuela Rubén Darío Carles Oberto',
      shortName: 'Rubén Darío Carles',
      latitude: 8.52810,
      longitude: -80.34680,
      address: 'Vía hacia Sonadora / Chigoré, Penonomé',
      type: 'Escuela Oficial',
      code: 'RDCO',
    ),
    SchoolLocation(
      id: 'SCH-09',
      name: 'Escuela Bilingüe Simeón Conte',
      shortName: 'Simeón Conte',
      latitude: 8.51930,
      longitude: -80.35748,
      address: 'Av. Nicanor Rosas y Calle del Estudiante, Penonomé',
      type: 'Escuela Bilingüe Oficial',
      code: 'EBSC',
    ),
  ];

  /// Resuelve las coordenadas de un colegio por nombre o retorna [defaultSchoolPoint].
  static LatLng resolveSchoolPoint(String? schoolName) {
    if (schoolName == null || schoolName.trim().isEmpty) {
      return defaultSchoolPoint;
    }
    final normalized = schoolName.trim().toLowerCase();
    for (final s in penonomeSchools) {
      if (s.name.toLowerCase().contains(normalized) ||
          normalized.contains(s.shortName.toLowerCase())) {
        return LatLng(s.latitude, s.longitude);
      }
    }
    return defaultSchoolPoint;
  }

  /// Calcula el tiempo estimado de llegada (ETA en minutos) dada distancia y velocidad.
  static int calculateEtaMinutes({
    required double distanceKm,
    required int speedKmH,
  }) {
    if (distanceKm <= 0) return 1;
    final effectiveSpeed = speedKmH > 5 ? speedKmH : 30;
    final minutes = ((distanceKm / effectiveSpeed) * 60).round();
    return minutes < 1 ? 1 : minutes;
  }
}
