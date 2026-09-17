import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Simula un Payload de un token JWT.
/// Almacena los datos del usuario que ha iniciado sesión, su rol y los tiempos de expiración.
class JwtSession {
  final String token;
  final int userId;
  final String name;
  final String email;
  final UserRole role;
  final int issuedAt;
  final int expiresAt;

  JwtSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.issuedAt,
    required this.expiresAt,
  });
}

/// Proveedor falso (Mock) de tokens JWT.
/// Genera sesiones estáticas para los diferentes roles con fines de demostración.
class FakeJwtProvider {
  static JwtSession createSessionForRole(UserRole role) {
    final issuedAt = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = issuedAt + 3600000; // Expira en 1 hora

    switch (role) {
      case UserRole.student:
        return JwtSession(
          token: "fake.jwt.student.token",
          userId: 1,
          name: "Ana Martínez",
          email: "ana.estudiante@universidad.edu",
          role: UserRole.student,
          issuedAt: issuedAt,
          expiresAt: expiresAt,
        );
      case UserRole.admin:
        return JwtSession(
          token: "fake.jwt.admin.token",
          userId: 2,
          name: "Admin SmartRoute",
          email: "admin@smartroute.edu",
          role: UserRole.admin,
          issuedAt: issuedAt,
          expiresAt: expiresAt,
        );
      case UserRole.driver:
        return JwtSession(
          token: "fake.jwt.driver.token",
          userId: 3,
          name: "Carlos Pérez",
          email: "carlos.conductor@transporte.edu",
          role: UserRole.driver,
          issuedAt: issuedAt,
          expiresAt: expiresAt,
        );
      case UserRole.owner:
        return JwtSession(
          token: "fake.jwt.owner.token",
          userId: 4,
          name: "Transporte Universitario Penonomé",
          email: "transportista@buses.edu",
          role: UserRole.owner,
          issuedAt: issuedAt,
          expiresAt: expiresAt,
        );
    }
  }
}

/// Gestor de estado global de la sesión.
/// Extiende [ChangeNotifier] para que cualquier widget que lo escuche (watch)
/// se reconstruya automáticamente cuando el usuario inicie o cierre sesión.
class SessionManager extends ChangeNotifier {
  JwtSession? _currentSession;

  /// Obtiene la sesión actual, o `null` si no hay sesión iniciada.
  JwtSession? get currentSession => _currentSession;

  /// Inicia sesión simulando una respuesta del servidor basándose en el rol.
  void login(UserRole role) {
    _currentSession = FakeJwtProvider.createSessionForRole(role);
    notifyListeners(); // Notifica a la app para reconstruir la interfaz
  }

  /// Cierra la sesión activa y borra los datos.
  void logout() {
    _currentSession = null;
    notifyListeners(); // Notifica a la app (útil para que GoRouter redirija al Login)
  }

  /// Retorna `true` si hay un usuario logueado actualmente.
  bool get isLoggedIn => _currentSession != null;

  /// Obtiene el rol del usuario actual.
  UserRole? get currentRole => _currentSession?.role;

  /// Obtiene el nombre del usuario actual.
  String get currentUserName => _currentSession?.name ?? "Invitado";

  /// Obtiene el token JWT del usuario actual.
  String? get currentToken => _currentSession?.token;

  /// Verifica si el token simulado ha expirado.
  bool get isSessionExpired {
    if (_currentSession == null) return true;
    return DateTime.now().millisecondsSinceEpoch > _currentSession!.expiresAt;
  }
}
