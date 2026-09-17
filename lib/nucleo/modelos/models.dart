/// Define la dirección de una ruta, útil para mostrar en la interfaz si el bus va 
/// hacia la Universidad o regresa hacia el Boulevard.
enum RouteDirection {
  boulevardToUniversity('Boulevard → Universidad'),
  universityToBoulevard('Universidad → Boulevard');

  final String displayName;
  const RouteDirection(this.displayName);
}

/// Modelo de datos que representa a un Autobús (Unidad de transporte).
/// Contiene información del vehículo, su conductor, su dueño y su estado actual en el mapa simulado.
class BusMock {
  final int id;
  final String code;
  final String plate;
  final String model;
  final int capacity;
  final String status; // "En recorrido", "Disponible", "Detenido", "Finalizado"
  final String driverName;
  final String ownerName;
  final String? routeName;
  final bool simulatedGpsActive;
  final int currentSpeedKmH;
  final String lastUpdate;

  BusMock({
    required this.id,
    required this.code,
    required this.plate,
    required this.model,
    required this.capacity,
    required this.status,
    required this.driverName,
    required this.ownerName,
    this.routeName,
    required this.simulatedGpsActive,
    this.currentSpeedKmH = 0,
    this.lastUpdate = 'Hace 1 minuto',
  });
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
}

enum UserRole {
  student('Estudiante'),
  admin('Administrador'),
  driver('Conductor'),
  owner('Transportista');

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

