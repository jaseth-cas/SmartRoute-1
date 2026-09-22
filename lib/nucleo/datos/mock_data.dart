import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';

class MockData {
  static final List<BusMock> buses = [
    BusMock(
      id: 1,
      code: 'BUS-01',
      plate: '123456',
      model: 'Toyota Coaster',
      capacity: 30,
      status: 'En recorrido',
      driverName: 'Juan Pérez',
      ownerName: 'Transportes SA',
      routeName: 'Ruta Universidad - Centro',
      simulatedGpsActive: true,
      currentSpeedKmH: 45,
    ),
    BusMock(
      id: 2,
      code: 'BUS-02',
      plate: '654321',
      model: 'Nissan Civilian',
      capacity: 28,
      status: 'Disponible',
      driverName: 'Carlos López',
      ownerName: 'Transportes SA',
      simulatedGpsActive: false,
    ),
  ];

  static List<RouteMock> routes = [
    RouteMock(
      id: 1,
      code: 'R-UB',
      name: 'Ruta Universidad - Boulevard',
      origin: 'Universidad',
      destination: 'Boulevard',
      status: 'Activa',
      etaMinutes: 5,
      busCode: 'BUS-01',
      direction: RouteDirection.universityToBoulevard,
      description: 'Ruta principal que conecta la universidad con el centro',
      isFavorite: true,
    ),
    RouteMock(
      id: 2,
      code: 'R-BU',
      name: 'Ruta Boulevard - Universidad',
      origin: 'Boulevard',
      destination: 'Universidad',
      status: 'Activa',
      etaMinutes: 12,
      busCode: 'BUS-02',
      direction: RouteDirection.boulevardToUniversity,
      description: 'Ruta de regreso hacia la universidad',
      isFavorite: false,
    ),
  ];

  static Future<void> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routesJson = prefs.getString('saved_routes');
    if (routesJson != null) {
      final List<dynamic> decodedList = jsonDecode(routesJson);
      routes = decodedList.map((json) => RouteMock.fromJson(json)).toList();
    }
  }

  static Future<void> saveRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routesJson = jsonEncode(routes.map((r) => r.toJson()).toList());
    await prefs.setString('saved_routes', routesJson);
  }

  static Future<void> loadStops() async {
    final prefs = await SharedPreferences.getInstance();
    final stopsJson = prefs.getString('saved_stops');
    if (stopsJson != null) {
      final List<dynamic> decodedList = jsonDecode(stopsJson);
      stops = decodedList.map((json) => StopMock.fromJson(json)).toList();
    }
  }

  static Future<void> saveStops() async {
    final prefs = await SharedPreferences.getInstance();
    final stopsJson = jsonEncode(stops.map((s) => s.toJson()).toList());
    await prefs.setString('saved_stops', stopsJson);
  }

  static List<StopMock> stops = [
    // Paradas para R-UB (Universidad -> Boulevard)
    StopMock(
      id: 11,
      routeCode: 'R-UB',
      stopCode: 'P-UB-001',
      name: 'Universidad',
      reference: 'Punto de salida',
      order: 1,
      distanceFromStartKm: 0.0,
      latitude: 8.520,
      longitude: -80.360,
      isFavorite: true,
    ),
    StopMock(
      id: 12,
      routeCode: 'R-UB',
      stopCode: 'P-UB-002',
      name: 'Super Xtra',
      reference: 'Área comercial Xtra',
      order: 2,
      distanceFromStartKm: 1.0,
      latitude: 8.519,
      longitude: -80.359,
      isFavorite: false,
    ),
    StopMock(
      id: 13,
      routeCode: 'R-UB',
      stopCode: 'P-UB-003',
      name: 'Hospital',
      reference: 'Sector Hospital',
      order: 3,
      distanceFromStartKm: 2.5,
      latitude: 8.518,
      longitude: -80.358,
      isFavorite: false,
    ),
    StopMock(
      id: 14,
      routeCode: 'R-UB',
      stopCode: 'P-UB-004',
      name: 'Buena Aventura',
      reference: 'Parada Buena Aventura',
      order: 4,
      distanceFromStartKm: 3.3,
      latitude: 8.517,
      longitude: -80.357,
      isFavorite: false,
    ),
    StopMock(
      id: 15,
      routeCode: 'R-UB',
      stopCode: 'P-UB-005',
      name: 'Super 99',
      reference: 'Área comercial',
      order: 5,
      distanceFromStartKm: 4.0,
      latitude: 8.516,
      longitude: -80.356,
      isFavorite: false,
    ),
    StopMock(
      id: 16,
      routeCode: 'R-UB',
      stopCode: 'P-UB-006',
      name: 'Cochez',
      reference: 'Cerca de Cochez',
      order: 6,
      distanceFromStartKm: 4.7,
      latitude: 8.515,
      longitude: -80.355,
      isFavorite: false,
    ),
    StopMock(
      id: 17,
      routeCode: 'R-UB',
      stopCode: 'P-UB-007',
      name: 'Boulevard',
      reference: 'Punto de llegada',
      order: 7,
      distanceFromStartKm: 5.5,
      latitude: 8.514,
      longitude: -80.354,
      isFavorite: false,
    ),
    
    // Paradas para R-BU (Boulevard -> Universidad)
    StopMock(
      id: 1,
      routeCode: 'R-BU',
      stopCode: 'P-BU-001',
      name: 'Boulevard',
      reference: 'Punto de salida',
      order: 1,
      distanceFromStartKm: 0.0,
      latitude: 8.514,
      longitude: -80.354,
      isFavorite: true,
    ),
    StopMock(
      id: 2,
      routeCode: 'R-BU',
      stopCode: 'P-BU-002',
      name: 'Cochez',
      reference: 'Cerca de Cochez',
      order: 2,
      distanceFromStartKm: 0.8,
      latitude: 8.515,
      longitude: -80.355,
      isFavorite: false,
    ),
    StopMock(
      id: 3,
      routeCode: 'R-BU',
      stopCode: 'P-BU-003',
      name: 'Super 99',
      reference: 'Área comercial',
      order: 3,
      distanceFromStartKm: 1.5,
      latitude: 8.516,
      longitude: -80.356,
      isFavorite: false,
    ),
    StopMock(
      id: 4,
      routeCode: 'R-BU',
      stopCode: 'P-BU-004',
      name: 'Buena Aventura',
      reference: 'Parada Buena Aventura',
      order: 4,
      distanceFromStartKm: 2.2,
      latitude: 8.517,
      longitude: -80.357,
      isFavorite: false,
    ),
    StopMock(
      id: 5,
      routeCode: 'R-BU',
      stopCode: 'P-BU-005',
      name: 'Hospital',
      reference: 'Sector Hospital',
      order: 5,
      distanceFromStartKm: 3.0,
      latitude: 8.518,
      longitude: -80.358,
      isFavorite: false,
    ),
    StopMock(
      id: 6,
      routeCode: 'R-BU',
      stopCode: 'P-BU-006',
      name: 'Super Xtra',
      reference: 'Área comercial Xtra',
      order: 6,
      distanceFromStartKm: 4.5,
      latitude: 8.519,
      longitude: -80.359,
      isFavorite: false,
    ),
    // Agregamos también la parada final de la Universidad
    StopMock(
      id: 7,
      routeCode: 'R-BU',
      stopCode: 'P-BU-007',
      name: 'Universidad',
      reference: 'Punto de llegada',
      order: 7,
      distanceFromStartKm: 5.5,
      latitude: 8.520,
      longitude: -80.360,
      isFavorite: false,
    ),
  ];

  static final List<NotificationMock> notifications = [
    NotificationMock(
      id: 1,
      title: 'Retraso en la ruta',
      message: 'El BUS-01 ha reportado un pequeño retraso por tráfico.',
      time: 'Hace 5 min',
      read: false,
      type: 'alert',
    ),
    NotificationMock(
      id: 2,
      title: 'Bus acercándose',
      message: 'Tu bus a la universidad está a 5 minutos de tu parada.',
      time: 'Hace 10 min',
      read: true,
      type: 'info',
    ),
  ];

  static RouteMock? getRouteByCode(String code) {
    return routes.where((r) => r.code == code).firstOrNull;
  }

  static BusMock? getBusByCode(String code) {
    return buses.where((b) => b.code == code).firstOrNull;
  }

  static List<StopMock> getStopsByRouteCode(String code) {
    return stops.where((s) => s.routeCode == code).toList();
  }

  static RouteMock? getDefaultStudentRoute() {
    return routes.isNotEmpty ? routes.first : null;
  }

  static StopMock? getDefaultStudentStop() {
    return stops.isNotEmpty ? stops.first : null;
  }
}
