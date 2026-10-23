/// Define la dirección de una ruta, útil para mostrar en la interfaz si el bus escolar va 
/// hacia el Colegio o regresa hacia los domicilios.
enum RouteDirection {
  homeToSchool('Domicilio → Colegio'),
  schoolToHome('Colegio → Domicilio');

  final String displayName;
  const RouteDirection(this.displayName);
}

/// Modelo de datos que representa a un Autobús (Unidad de transporte escolar / privado).
/// Contiene información del vehículo, su conductor, su dueño, capacidad de cupos y estado actual.
class BusMock {
  final int id;
  final String code;
  final String plate;
  final String model;
  final int capacity;
  final int seatsOccupied;
  final String status; // "En recorrido", "Disponible", "Detenido", "Finalizado"
  final String driverName;
  final String ownerName;
  final String? routeName;
  final bool simulatedGpsActive;
  final int currentSpeedKmH;
  final String lastUpdate;
  final bool isVerified;
  final String? schoolName;
  final double? latitude;
  final double? longitude;

  BusMock({
    required this.id,
    required this.code,
    required this.plate,
    required this.model,
    required this.capacity,
    this.seatsOccupied = 0,
    required this.status,
    required this.driverName,
    required this.ownerName,
    this.routeName,
    required this.simulatedGpsActive,
    this.currentSpeedKmH = 0,
    this.lastUpdate = 'Hace 1 minuto',
    this.isVerified = true,
    this.schoolName,
    this.latitude,
    this.longitude,
  });

  factory BusMock.fromMap(Map<String, dynamic> map) {
    return BusMock(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      code: map['codigo'] ?? map['code'] ?? '',
      plate: map['placa'] ?? map['plate'] ?? '',
      model: map['modelo'] ?? map['model'] ?? '',
      capacity: map['capacidad'] ?? map['capacity'] ?? 16,
      seatsOccupied: map['asientos_ocupados'] ?? map['seatsOccupied'] ?? 0,
      status: map['estado'] ?? map['status'] ?? 'Disponible',
      driverName: map['conductor_nombre'] ?? map['driverName'] ?? 'Conductor Asignado',
      ownerName: map['dueno_nombre'] ?? map['ownerName'] ?? 'Transportes Escolar',
      routeName: map['nombre_ruta'] ?? map['routeName'],
      simulatedGpsActive: map['simulatedGpsActive'] ?? true,
      currentSpeedKmH: map['velocidad_kmh'] ?? map['currentSpeedKmH'] ?? 0,
      lastUpdate: 'En vivo',
      isVerified: map['is_verified'] ?? true,
      schoolName: map['colegio_asignado'] ?? map['schoolName'] ?? 'Colegio San José',
      latitude: (map['latitud_actual'] ?? map['latitude'])?.toDouble(),
      longitude: (map['longitud_actual'] ?? map['longitude'])?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': code,
      'placa': plate,
      'modelo': model,
      'capacidad': capacity,
      'asientos_ocupados': seatsOccupied,
      'estado': status,
      'colegio_asignado': schoolName,
      'nombre_ruta': routeName,
      'velocidad_kmh': currentSpeedKmH,
      if (latitude != null) 'latitud_actual': latitude,
      if (longitude != null) 'longitud_actual': longitude,
      'is_verified': isVerified,
    };
  }
}

/// Modelo de datos para las Rutas del sistema.
/// Maneja la información general de la trayectoria (origen, destino) y los autobuses asignados.
class RouteMock {
  final int id;
  final String code;
  final String name;
  final String origin;
  final String destination;
  final String status;
  final int? etaMinutes;
  final String? busCode;
  final RouteDirection direction;
  final String description;
  final bool isFavorite;

  RouteMock({
    required this.id,
    required this.code,
    required this.name,
    required this.origin,
    required this.destination,
    required this.status,
    this.etaMinutes,
    this.busCode,
    required this.direction,
    required this.description,
    required this.isFavorite,
  });

  RouteMock copyWith({
    int? id,
    String? code,
    String? name,
    String? origin,
    String? destination,
    String? status,
    int? etaMinutes,
    String? busCode,
    RouteDirection? direction,
    String? description,
    bool? isFavorite,
  }) {
    return RouteMock(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      busCode: busCode ?? this.busCode,
      direction: direction ?? this.direction,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'origin': origin,
      'destination': destination,
      'status': status,
      'etaMinutes': etaMinutes,
      'busCode': busCode,
      'direction': direction.name, // Guardar el enum como string
      'description': description,
      'isFavorite': isFavorite,
    };
  }

  factory RouteMock.fromJson(Map<String, dynamic> json) {
    return RouteMock(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      origin: json['origin'],
      destination: json['destination'],
      status: json['status'],
      etaMinutes: json['etaMinutes'],
      busCode: json['busCode'],
      direction: RouteDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => RouteDirection.homeToSchool,
      ),
      description: json['description'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

/// Modelo de datos para las Paradas (Stops).
/// Representa un punto de detención a lo largo de una ruta específica.
class StopMock {
  final int id;
  final String routeCode;
  final String stopCode;
  final String name;
  final String reference;
  final int order;
  final double distanceFromStartKm;
  final double? latitude;
  final double? longitude;
  final bool isFavorite;

  StopMock({
    required this.id,
    required this.routeCode,
    required this.stopCode,
    required this.name,
    required this.reference,
    required this.order,
    required this.distanceFromStartKm,
    this.latitude,
    this.longitude,
    required this.isFavorite,
  });

  StopMock copyWith({
    int? id,
    String? routeCode,
    String? stopCode,
    String? name,
    String? reference,
    int? order,
    double? distanceFromStartKm,
    double? latitude,
    double? longitude,
    bool? isFavorite,
  }) {
    return StopMock(
      id: id ?? this.id,
      routeCode: routeCode ?? this.routeCode,
      stopCode: stopCode ?? this.stopCode,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      order: order ?? this.order,
      distanceFromStartKm: distanceFromStartKm ?? this.distanceFromStartKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeCode': routeCode,
      'stopCode': stopCode,
      'name': name,
      'reference': reference,
      'order': order,
      'distanceFromStartKm': distanceFromStartKm,
      'latitude': latitude,
      'longitude': longitude,
      'isFavorite': isFavorite,
    };
  }

  factory StopMock.fromJson(Map<String, dynamic> json) {
    return StopMock(
      id: json['id'],
      routeCode: json['routeCode'],
      stopCode: json['stopCode'],
      name: json['name'],
      reference: json['reference'],
      order: json['order'],
      distanceFromStartKm: json['distanceFromStartKm']?.toDouble() ?? 0.0,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}

class NotificationMock {
  final int id;
  final String title;
  final String message;
  final String time;
  final bool read;
  final String type; // "alert", "info", "system"

  NotificationMock({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.read,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time,
      'read': read,
      'type': type,
    };
  }

  factory NotificationMock.fromJson(Map<String, dynamic> json) {
    return NotificationMock(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      time: json['time'],
      read: json['read'] ?? false,
      type: json['type'],
    );
  }
}

enum UserRole {
  student('Padre / Familia'),
  driver('Conductor Escolar'),
  owner('Transportista / Flota');

  final String displayName;
  const UserRole(this.displayName);
}

class UserMock {
  final int id;
  final String name;
  final String email;
  final UserRole role;

  UserMock({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

class StudentPreferenceMock {
  final bool notificationsEnabled;
  final int proximityAlertMinutes;
  final List<int> favoriteRouteIds;
  final List<int> favoriteStopIds;

  StudentPreferenceMock({
    required this.notificationsEnabled,
    required this.proximityAlertMinutes,
    required this.favoriteRouteIds,
    required this.favoriteStopIds,
  });
}

/// Estado de abordaje y asistencia del estudiante en la ruta escolar
enum PassengerStatus {
  waiting('En espera de recogida'),
  onboard('A bordo del bus'),
  delivered('En colegio / destino'),
  absent('Ausente hoy');

  final String displayName;
  const PassengerStatus(this.displayName);
}

/// Representa a un estudiante / pasajero asignado a un cupo en un bus privado
class StudentPassengerMock {
  final int id;
  final String name;
  final String parentName;
  final String parentPhone;
  final String schoolName;
  final String pickupAddress;
  final String busCode;
  final String routeCode;
  final int order;
  final PassengerStatus status;
  final String? lastBoardingTime;
  final String? boardingMethod; // "Biometría Facial AI", "Manual"
  final double monthlyFee;
  final String paymentStatus; // "Al día", "Pendiente", "En mora"
  final String? photoAsset;

  StudentPassengerMock({
    required this.id,
    required this.name,
    required this.parentName,
    required this.parentPhone,
    required this.schoolName,
    required this.pickupAddress,
    required this.busCode,
    required this.routeCode,
    required this.order,
    required this.status,
    this.lastBoardingTime,
    this.boardingMethod,
    this.monthlyFee = 65000,
    this.paymentStatus = 'Al día',
    this.photoAsset,
  });

  StudentPassengerMock copyWith({
    int? id,
    String? name,
    String? parentName,
    String? parentPhone,
    String? schoolName,
    String? pickupAddress,
    String? busCode,
    String? routeCode,
    int? order,
    PassengerStatus? status,
    String? lastBoardingTime,
    String? boardingMethod,
    double? monthlyFee,
    String? paymentStatus,
    String? photoAsset,
  }) {
    return StudentPassengerMock(
      id: id ?? this.id,
      name: name ?? this.name,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      schoolName: schoolName ?? this.schoolName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      busCode: busCode ?? this.busCode,
      routeCode: routeCode ?? this.routeCode,
      order: order ?? this.order,
      status: status ?? this.status,
      lastBoardingTime: lastBoardingTime ?? this.lastBoardingTime,
      boardingMethod: boardingMethod ?? this.boardingMethod,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      photoAsset: photoAsset ?? this.photoAsset,
    );
  }

  factory StudentPassengerMock.fromMap(
    Map<String, dynamic> map, [
    Map<String, dynamic>? attendanceMap,
  ]) {
    PassengerStatus parsedStatus = PassengerStatus.waiting;
    String? lastBoardingTime;
    String? boardingMethod;

    final rawStatus = attendanceMap?['estado'] ?? map['status'];
    if (rawStatus != null) {
      switch (rawStatus) {
        case 'onboard':
          parsedStatus = PassengerStatus.onboard;
          break;
        case 'delivered':
          parsedStatus = PassengerStatus.delivered;
          break;
        case 'absent':
          parsedStatus = PassengerStatus.absent;
          break;
        default:
          parsedStatus = PassengerStatus.waiting;
      }
    }
    lastBoardingTime = attendanceMap?['hora_abordaje'];
    boardingMethod = attendanceMap?['metodo_abordaje'];

    return StudentPassengerMock(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      name: map['nombre'] ?? map['name'] ?? '',
      parentName: map['padre_nombre'] ?? map['parentName'] ?? '',
      parentPhone: map['padre_telefono'] ?? map['parentPhone'] ?? '',
      schoolName: map['colegio'] ?? map['schoolName'] ?? 'Colegio San José',
      pickupAddress: map['direccion_recogida'] ?? map['pickupAddress'] ?? '',
      busCode: map['autobus_codigo'] ?? map['busCode'] ?? 'BUS-01',
      routeCode: map['routeCode'] ?? 'R-01',
      order: map['orden'] ?? map['order'] ?? 1,
      status: parsedStatus,
      lastBoardingTime: lastBoardingTime,
      boardingMethod: boardingMethod,
      monthlyFee: (map['cuota_mensual'] ?? map['monthlyFee']) != null
          ? double.tryParse(map['cuota_mensual'].toString()) ?? 65.0
          : 65.0,
      paymentStatus: map['estado_pago'] ?? map['paymentStatus'] ?? 'Al día',
      photoAsset: map['photoAsset'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': name,
      'padre_nombre': parentName,
      'padre_telefono': parentPhone,
      'colegio': schoolName,
      'direccion_recogida': pickupAddress,
      'autobus_codigo': busCode,
      'orden': order,
      'cuota_mensual': monthlyFee,
      'estado_pago': paymentStatus,
    };
  }
}

/// Resumen de ocupación y finanzas para el dueño de flota (SaaS / Transportista)
class FleetFinancialSummary {
  final int totalSeats;
  final int occupiedSeats;
  final double totalRevenue;
  final double pendingRevenue;
  final int pendingPaymentsCount;
  final int totalStudents;

  const FleetFinancialSummary({
    required this.totalSeats,
    required this.occupiedSeats,
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.pendingPaymentsCount,
    required this.totalStudents,
  });

  double get occupancyRate => totalSeats > 0 ? (occupiedSeats / totalSeats) * 100 : 0.0;
}

