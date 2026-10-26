import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';

class MockData {
  static final List<BusMock> buses = [
    BusMock(
      id: 1,
      code: 'BUS-01',
      plate: 'TBX-492',
      model: 'Toyota HiAce',
      capacity: 14,
      seatsOccupied: 8,
      status: 'En recorrido',
      driverName: 'Juan Pérez',
      ownerName: 'Transportes Gómez (Independiente)',
      routeName: 'Ruta Escolar Norte - Col. San José',
      simulatedGpsActive: true,
      currentSpeedKmH: 38,
      isVerified: true,
      schoolName: 'Colegio San José',
    ),
    BusMock(
      id: 2,
      code: 'BUS-02',
      plate: 'SKL-810',
      model: 'Nissan Civilian',
      capacity: 20,
      seatsOccupied: 18,
      status: 'Disponible',
      driverName: 'Carlos López',
      ownerName: 'Transportes Gómez (Independiente)',
      routeName: 'Ruta Escolar Sur - Col. Santa María',
      simulatedGpsActive: false,
      isVerified: true,
      schoolName: 'Colegio Santa María',
    ),
  ];

  static List<RouteMock> routes = [
    RouteMock(
      id: 1,
      code: 'R-UB',
      name: 'Ruta Escolar Norte - Col. San José',
      origin: 'Residencial San Carlos',
      destination: 'Colegio San José',
      status: 'Activa',
      etaMinutes: 5,
      busCode: 'BUS-01',
      direction: RouteDirection.homeToSchool,
      description: 'Ruta principal de recogida matutina hacia el Colegio San José',
      isFavorite: true,
    ),
    RouteMock(
      id: 2,
      code: 'R-BU',
      name: 'Ruta Retorno Tarde - Col. San José',
      origin: 'Colegio San José',
      destination: 'Residencial San Carlos',
      status: 'Activa',
      etaMinutes: 12,
      busCode: 'BUS-02',
      direction: RouteDirection.schoolToHome,
      description: 'Ruta escolar de retorno de la tarde hacia los domicilios',
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

  static Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifsJson = prefs.getString('saved_notifications');
    if (notifsJson != null) {
      final List<dynamic> decodedList = jsonDecode(notifsJson);
      notifications = decodedList.map((json) => NotificationMock.fromJson(json)).toList();
    }
  }

  static Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifsJson = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString('saved_notifications', notifsJson);
  }

  static Future<void> addNotification(NotificationMock notification) async {
    notifications.insert(0, notification);
    await saveNotifications();
  }

  static List<StopMock> stops = [
    // Paradas para R-UB (Residencial -> Colegio San José)
    StopMock(
      id: 11,
      routeCode: 'R-UB',
      stopCode: 'P-UB-001',
      name: 'Colegio San José',
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
      name: 'Residencial San Carlos',
      reference: 'Punto de llegada',
      order: 7,
      distanceFromStartKm: 5.5,
      latitude: 8.514,
      longitude: -80.354,
      isFavorite: false,
    ),
    
    // Paradas para R-BU (Colegio -> Residencial)
    StopMock(
      id: 1,
      routeCode: 'R-BU',
      stopCode: 'P-BU-001',
      name: 'Residencial San Carlos',
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
    // Agregamos también la parada final del Colegio
    StopMock(
      id: 7,
      routeCode: 'R-BU',
      stopCode: 'P-BU-007',
      name: 'Colegio San José',
      reference: 'Punto de llegada',
      order: 7,
      distanceFromStartKm: 5.5,
      latitude: 8.520,
      longitude: -80.360,
      isFavorite: false,
    ),
  ];

  static List<NotificationMock> notifications = [
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
      message: 'Tu bus escolar está a 5 minutos de tu domicilio.',
      time: 'Hace 10 min',
      read: true,
      type: 'info',
    ),
  ];

  /// Lista de estudiantes / pasajeros asignados a la flota escolar
  static List<StudentPassengerMock> passengers = [
    StudentPassengerMock(
      id: 1,
      name: 'Mateo Gómez',
      parentName: 'Carlos Gómez',
      parentPhone: '+57 300 123 4567',
      schoolName: 'Colegio San José',
      pickupAddress: 'Calle 45 # 12-30 (Casa)',
      busCode: 'BUS-01',
      routeCode: 'R-UB',
      order: 1,
      status: PassengerStatus.onboard,
      lastBoardingTime: '07:14 AM',
      boardingMethod: 'Biometría Facial AI',
      monthlyFee: 65000,
      paymentStatus: 'Al día',
    ),
    StudentPassengerMock(
      id: 2,
      name: 'Sofía Martínez',
      parentName: 'Lucía Martínez',
      parentPhone: '+57 311 987 6543',
      schoolName: 'Colegio San José',
      pickupAddress: 'Cra 15 # 80-22 (Conjunto Roble)',
      busCode: 'BUS-01',
      routeCode: 'R-UB',
      order: 2,
      status: PassengerStatus.onboard,
      lastBoardingTime: '07:22 AM',
      boardingMethod: 'Biometría Facial AI',
      monthlyFee: 65000,
      paymentStatus: 'Al día',
    ),
    StudentPassengerMock(
      id: 3,
      name: 'Lucas Rodríguez',
      parentName: 'Andrés Rodríguez',
      parentPhone: '+57 315 444 3322',
      schoolName: 'Colegio San José',
      pickupAddress: 'Av. 19 # 104-50 (Edif. Almirante)',
      busCode: 'BUS-01',
      routeCode: 'R-UB',
      order: 3,
      status: PassengerStatus.waiting,
      lastBoardingTime: null,
      boardingMethod: null,
      monthlyFee: 65000,
      paymentStatus: 'Pendiente',
    ),
    StudentPassengerMock(
      id: 5,
      name: 'Eliam Fernandez',
      parentName: 'Elena Fernández',
      parentPhone: '+507 6712-3490',
      schoolName: 'Colegio San José',
      pickupAddress: 'Vía Cristo Rey, Penonomé',
      busCode: 'BUS-01',
      routeCode: 'R-UB',
      order: 4,
      status: PassengerStatus.waiting,
      lastBoardingTime: null,
      boardingMethod: null,
      monthlyFee: 65000,
      paymentStatus: 'Al día',
      photoAsset: 'assets/images/eliam_student.png',
    ),
    StudentPassengerMock(
      id: 4,
      name: 'Valentina Castro',
      parentName: 'Patricia Castro',
      parentPhone: '+57 320 555 8899',
      schoolName: 'Colegio San José',
      pickupAddress: 'Calle 72 # 9-15 (Torres del Parque)',
      busCode: 'BUS-01',
      routeCode: 'R-UB',
      order: 5,
      status: PassengerStatus.absent,
      lastBoardingTime: null,
      boardingMethod: null,
      monthlyFee: 65000,
      paymentStatus: 'Al día',
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

  /// Retorna el estudiante principal asociado a la vista de padre/estudiante de la demo
  static StudentPassengerMock getPrimaryStudent() {
    return passengers.first;
  }

  /// Obtiene los pasajeros asignados a una unidad
  static List<StudentPassengerMock> getPassengersByBus(String busCode) {
    return passengers.where((p) => p.busCode == busCode).toList();
  }

  /// Registra o anula el reporte de ausencia de un estudiante (Ahorro de ruta)
  static void reportAbsence(int studentId, bool isAbsent) {
    final index = passengers.indexWhere((p) => p.id == studentId);
    if (index != -1) {
      final current = passengers[index];
      passengers[index] = current.copyWith(
        status: isAbsent ? PassengerStatus.absent : PassengerStatus.waiting,
      );
    }
  }

  /// Registra el abordaje del estudiante mediante biometría facial o manual
  static void checkInPassenger(int studentId, {String method = 'Biometría Facial AI'}) {
    final index = passengers.indexWhere((p) => p.id == studentId);
    if (index != -1) {
      final now = DateTime.now();
      final formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      passengers[index] = passengers[index].copyWith(
        status: PassengerStatus.onboard,
        lastBoardingTime: formattedTime,
        boardingMethod: method,
      );
    }
  }

  /// Marca la entrega del estudiante en el colegio o destino
  static void checkOutPassenger(int studentId) {
    final index = passengers.indexWhere((p) => p.id == studentId);
    if (index != -1) {
      passengers[index] = passengers[index].copyWith(
        status: PassengerStatus.delivered,
      );
    }
  }

  /// Resumen financiero y de cupos de la flota para el transportista independiente
  static FleetFinancialSummary getFleetFinancialSummary() {
    int totalSeats = 0;
    int occupiedSeats = 0;
    for (final bus in buses) {
      totalSeats += bus.capacity;
      occupiedSeats += bus.seatsOccupied;
    }

    double totalRevenue = 0;
    double pendingRevenue = 0;
    int pendingCount = 0;

    for (final p in passengers) {
      if (p.paymentStatus == 'Al día') {
        totalRevenue += p.monthlyFee;
      } else {
        pendingRevenue += p.monthlyFee;
        pendingCount++;
      }
    }

    return FleetFinancialSummary(
      totalSeats: totalSeats,
      occupiedSeats: occupiedSeats,
      totalRevenue: totalRevenue,
      pendingRevenue: pendingRevenue,
      pendingPaymentsCount: pendingCount,
      totalStudents: passengers.length,
    );
  }
}
