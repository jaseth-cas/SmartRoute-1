import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio encargado de la comunicación con Supabase Auth y la tabla de `perfiles`.
class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Retorna el usuario autenticado actualmente en Supabase (o null)
  User? get currentUser => _supabase.auth.currentUser;

  /// Retorna la sesión activa actual con sus tokens JWT
  Session? get currentSession => _supabase.auth.currentSession;

  /// Inicia sesión con correo y contraseña en Supabase GoTrue
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registra una nueva cuenta en Supabase y crea su fila en la tabla `perfiles`
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nombre,
    required UserRole rol,
    String? telefono,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'nombre': nombre.trim(),
        'rol': rol.name, // 'student', 'driver', 'owner'
      },
    );

    final user = response.user;
    if (user != null) {
      // Insertar el perfil con su rol asignado en la base de datos
      try {
        await _supabase.from('perfiles').upsert({
          'id': user.id,
          'nombre': nombre.trim(),
          'email': email.trim(),
          'rol': rol.name,
          'telefono': telefono,
        });
      } catch (e) {
        debugPrint('Aviso al insertar perfil: $e');
      }
    }

    return response;
  }

  /// Obtiene los datos del perfil del usuario autenticado (nombre y rol)
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Error obteniendo perfil: $e');
      return null;
    }
  }

  /// Cierra la sesión activa en el servidor y limpia tokens
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
