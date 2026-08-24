import '../models/models.dart';

/// Base de datos en memoria (Simulada).
/// En un escenario de producción real, estos datos vendrían de un backend (API REST / Firebase).
/// Almacena usuarios, rutas, paradas y notificaciones predeterminadas para que la 
/// app funcione sin conexión al servidor.
class MockData {
  static final List<UserMock> users = [
    UserMock(id: 1, name: "Ana Martínez", email: "ana.estudiante@universidad.edu", role: UserRole.student),
    UserMock(id: 2, name: "Admin SmartRoute", email: "admin@smartroute.edu", role: UserRole.admin),
    UserMock(id: 3, name: "Carlos Pérez", email: "carlos.conductor@transporte.edu", role: UserRole.driver),
    UserMock(id: 4, name: "Transporte Universitario Penonomé", email: "transportista@buses.edu", role: UserRole.owner),
  ];

  static final List<RouteMock> routes = [
    RouteMock(
      id: 1,
      code: "R-BU",
      name: "Ruta Boulevard → Universidad",
      origin: "Boulevard",
      destination: "Universidad",
      status: "Activa",
      etaMinutes: 12,
      busCode: "BUS-01",
      direction: RouteDirection.boulevardToUniversity,
      description: "Recorrido desde Boulevard hacia la zona universitaria vía baja (Hospital).",
      isFavorite: false,
    ),
    RouteMock(
      id: 2,
      code: "R-UB",
      name: "Ruta Universidad → Boulevard",
      origin: "Universidad",
      destination: "Boulevard",
      status: "Activa",
      etaMinutes: 15,
      busCode: "BUS-02",
      direction: RouteDirection.universityToBoulevard,
      description: "Recorrido desde la Universidad hacia Boulevard pasando por la Central de Penonomé (Vía Alta).",
      isFavorite: true,
    ),
  ];

  static final List<StopMock> stops = [
    // Ruta R-BU (Vía Baja - 10 paradas según actualización)
    StopMock(id: 1, routeCode: "R-BU", stopCode: "P-BU-001", name: "Boulevard", reference: "Punto de salida", order: 1, distanceFromStartKm: 0.0, latitude: 8.5100, longitude: -80.3500, isFavorite: false),
    StopMock(id: 2, routeCode: "R-BU", stopCode: "P-BU-002", name: "Cochez", reference: "Cerca de Cochez", order: 2, distanceFromStartKm: 0.8, latitude: 8.5120, longitude: -80.3520, isFavorite: false),
    StopMock(id: 3, routeCode: "R-BU", stopCode: "P-BU-003", name: "Super 99", reference: "Área comercial", order: 3, distanceFromStartKm: 1.5, latitude: 8.5140, longitude: -80.3540, isFavorite: false),
    StopMock(id: 4, routeCode: "R-BU", stopCode: "P-BU-004", name: "Buena Aventura", reference: "Parada Buena Aventura", order: 4, distanceFromStartKm: 2.2, latitude: 8.5160, longitude: -80.3560, isFavorite: false),
    StopMock(id: 5, routeCode: "R-BU", stopCode: "P-BU-005", name: "Hospital", reference: "Sector Hospital", order: 5, distanceFromStartKm: 3.0, latitude: 8.5180, longitude: -80.3580, isFavorite: false),
    StopMock(id: 6, routeCode: "R-BU", stopCode: "P-BU-006", name: "Super Xtra", reference: "Área comercial Xtra", order: 6, distanceFromStartKm: 3.6, latitude: 8.5260, longitude: -80.3540, isFavorite: false),
    StopMock(id: 7, routeCode: "R-BU", stopCode: "P-BU-007", name: "Parada de la IPT", reference: "Cerca de la IPT", order: 7, distanceFromStartKm: 4.2, latitude: 8.5240, longitude: -80.3560, isFavorite: false),
    StopMock(id: 8, routeCode: "R-BU", stopCode: "P-BU-008", name: "COEDUCO", reference: "Sector COEDUCO", order: 8, distanceFromStartKm: 4.8, latitude: 8.5220, longitude: -80.3580, isFavorite: false),
    StopMock(id: 9, routeCode: "R-BU", stopCode: "P-BU-009", name: "El Machetazo", reference: "Área comercial Machetazo", order: 9, distanceFromStartKm: 5.4, latitude: 8.5200, longitude: -80.3600, isFavorite: false),
    StopMock(id: 10, routeCode: "R-BU", stopCode: "P-BU-010", name: "Universidad", reference: "Zona universitaria", order: 10, distanceFromStartKm: 6.0, latitude: 8.5167, longitude: -80.3600, isFavorite: false),

    // Ruta R-UB (Vía Alta - 16 paradas)
    StopMock(id: 11, routeCode: "R-UB", stopCode: "P-UB-001", name: "Universidad", reference: "Salida UTP", order: 1, distanceFromStartKm: 0.0, latitude: 8.5167, longitude: -80.3600, isFavorite: true),
    StopMock(id: 12, routeCode: "R-UB", stopCode: "P-UB-002", name: "Parada del IMA", reference: "Cerca del IMA", order: 2, distanceFromStartKm: 0.5, latitude: 8.5180, longitude: -80.3620, isFavorite: false),
    StopMock(id: 13, routeCode: "R-UB", stopCode: "P-UB-003", name: "El Machetazo", reference: "Área Machetazo", order: 3, distanceFromStartKm: 1.2, latitude: 8.5200, longitude: -80.3600, isFavorite: false),
    StopMock(id: 14, routeCode: "R-UB", stopCode: "P-UB-004", name: "COEDUCO", reference: "Sector COEDUCO", order: 4, distanceFromStartKm: 1.8, latitude: 8.5220, longitude: -80.3580, isFavorite: false),
    StopMock(id: 15, routeCode: "R-UB", stopCode: "P-UB-005", name: "Parada en la IPT", reference: "Cerca IPT", order: 5, distanceFromStartKm: 2.4, latitude: 8.5240, longitude: -80.3560, isFavorite: false),
    StopMock(id: 16, routeCode: "R-UB", stopCode: "P-UB-006", name: "Super Xtra", reference: "Área Xtra", order: 6, distanceFromStartKm: 3.0, latitude: 8.5260, longitude: -80.3540, isFavorite: false),
    StopMock(id: 17, routeCode: "R-UB", stopCode: "P-UB-007", name: "Super Coclé", reference: "Sector Super Coclé", order: 7, distanceFromStartKm: 3.6, latitude: 8.5280, longitude: -80.3520, isFavorite: false),
    StopMock(id: 18, routeCode: "R-UB", stopCode: "P-UB-008", name: "El Banco", reference: "Zona central", order: 8, distanceFromStartKm: 4.2, latitude: 8.5140, longitude: -80.3580, isFavorite: false),
    StopMock(id: 19, routeCode: "R-UB", stopCode: "P-UB-009", name: "Casa Peter", reference: "Parada Casa Peter", order: 9, distanceFromStartKm: 4.8, latitude: 8.5120, longitude: -80.3560, isFavorite: false),
    StopMock(id: 20, routeCode: "R-UB", stopCode: "P-UB-010", name: "Mercado", reference: "Mercado Público", order: 10, distanceFromStartKm: 5.4, latitude: 8.5100, longitude: -80.3540, isFavorite: false),
    StopMock(id: 21, routeCode: "R-UB", stopCode: "P-UB-011", name: "Gimnasio", reference: "Parada Gimnasio", order: 11, distanceFromStartKm: 6.0, latitude: 8.5080, longitude: -80.3520, isFavorite: false),
    StopMock(id: 22, routeCode: "R-UB", stopCode: "P-UB-012", name: "Super Eva", reference: "Cerca Super Eva", order: 12, distanceFromStartKm: 6.6, latitude: 8.5060, longitude: -80.3500, isFavorite: false),
    StopMock(id: 23, routeCode: "R-UB", stopCode: "P-UB-013", name: "Ecomarket", reference: "Cerca Ecomarket", order: 13, distanceFromStartKm: 7.2, latitude: 8.5040, longitude: -80.3480, isFavorite: false),
    StopMock(id: 24, routeCode: "R-UB", stopCode: "P-UB-014", name: "IFARHU", reference: "Cerca IFARHU", order: 14, distanceFromStartKm: 7.8, latitude: 8.5020, longitude: -80.3460, isFavorite: false),
    StopMock(id: 25, routeCode: "R-UB", stopCode: "P-UB-015", name: "Hotel Village", reference: "Sector Village", order: 15, distanceFromStartKm: 8.4, latitude: 8.5000, longitude: -80.3440, isFavorite: false),
    StopMock(id: 26, routeCode: "R-UB", stopCode: "P-UB-016", name: "Boulevard", reference: "Punto final", order: 16, distanceFromStartKm: 9.0, latitude: 8.5100, longitude: -80.3500, isFavorite: false),
  ];

  static final List<BusMock> buses = [
    BusMock(id: 1, code: "BUS-01", plate: "123456", model: "Toyota Coaster", capacity: 30, status: "En recorrido", driverName: "Carlos Pérez", ownerName: "Transporte Universitario Penonomé", routeName: "Ruta Boulevard → Universidad", simulatedGpsActive: true, currentSpeedKmH: 35, lastUpdate: "Hace 1 minuto"),
    BusMock(id: 2, code: "BUS-02", plate: "654321", model: "Hyundai County", capacity: 28, status: "Disponible", driverName: "Luis Gómez", ownerName: "Transporte Universitario Penonomé", routeName: "Ruta Universidad → Boulevard", simulatedGpsActive: false, currentSpeedKmH: 0, lastUpdate: "Hace 15 minutos"),
  ];

  static final List<NotificationMock> notifications = [
    NotificationMock(id: 1, title: "Bus próximo", message: "El bus de la Ruta Universidad → Boulevard está a 5 minutos de tu parada.", time: "Hace 1 min", read: false, type: "alert"),
    NotificationMock(id: 2, title: "Ruta iniciada", message: "La ruta Universidad → Boulevard ha iniciado su recorrido.", time: "Hace 10 min", read: false, type: "info"),
    NotificationMock(id: 3, title: "Ubicación actualizada", message: "Nueva ubicación GPS simulada disponible.", time: "Hace 15 min", read: true, type: "system"),
    NotificationMock(id: 4, title: "Recorrido finalizado", message: "El bus ha finalizado recorrido.", time: "Hace 1 hora", read: true, type: "info"),
  ];
  
  static final StudentPreferenceMock studentPreferences = StudentPreferenceMock(
    notificationsEnabled: true,
    proximityAlertMinutes: 5,
    favoriteRouteIds: [2],
    favoriteStopIds: [11],
  );

  // Helper functions
  static List<StopMock> getStopsByRouteCode(String routeCode) {
    var result = stops.where((s) => s.routeCode == routeCode).toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  static RouteMock? getRouteByCode(String routeCode) {
    try {
      return routes.firstWhere((r) => r.code == routeCode);
    } catch (_) {
      return null;
    }
  }

  static BusMock? getBusByCode(String busCode) {
    try {
      return buses.firstWhere((b) => b.code == busCode);
    } catch (_) {
      return null;
    }
  }

  static RouteMock getDefaultStudentRoute() {
    try {
      return routes.firstWhere((r) => r.code == "R-UB");
    } catch (_) {
      return routes.first;
    }
  }

  static StopMock getDefaultStudentStop() {
    try {
      return stops.firstWhere((s) => s.stopCode == "P-UB-001");
    } catch (_) {
      return stops.first;
    }
  }
}
