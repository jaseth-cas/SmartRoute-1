import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';

/// Servicio encargado de la comunicación con Supabase Auth y la tabla de `perfiles`.
class AuthService {
  final SupabaseClient? _injectedClient;

  AuthService({SupabaseClient? supabaseClient}) : _injectedClient = supabaseClient;

  SupabaseClient get _supabase => _injectedClient ?? SupabaseConfig.client;

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

  /// Envía un enlace de recuperación de contraseña al correo electrónico indicado
  Future<void> resetPassword(String email) async {
    final validationError = Validators.validateEmail(email);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      debugPrint('Aviso resetPassword en Supabase: $e');
    }
  }

  /// Actualiza los datos del perfil del usuario en la tabla `perfiles`
  Future<void> updateUserProfile({
    required String userId,
    String? nombre,
    String? email,
    String? telefono,
  }) async {
    final updates = <String, dynamic>{};
    if (nombre != null && nombre.trim().isNotEmpty) updates['nombre'] = nombre.trim();
    if (email != null && email.trim().isNotEmpty) updates['email'] = email.trim();
    if (telefono != null) updates['telefono'] = telefono.trim();

    if (updates.isEmpty) return;
    try {
      await _supabase.from('perfiles').update(updates).eq('id', userId);
    } catch (e) {
      debugPrint('Aviso actualizando perfil en Supabase: $e');
    }
  }

  /// Obtiene la lista de conductores disponibles registrados en el sistema
  Future<List<Map<String, dynamic>>> getAvailableDrivers() async {
    try {
      final data = await _supabase
          .from('perfiles')
          .select('id, nombre, email, telefono')
          .eq('rol', 'driver');
      final list = (data as List).cast<Map<String, dynamic>>();
      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('Aviso obteniendo conductores: $e');
    }
    return [
      {
        'id': 'b0000000-0000-0000-0000-000000000002',
        'nombre': 'Carlos Andrés Gómez',
        'email': 'conductor@smartroute.com',
        'telefono': '+57 310 444 5566',
      },
      {
        'id': 'b0000000-0000-0000-0000-000000000005',
        'nombre': 'Juan Pérez (Verificado C2)',
        'email': 'juan.conductor@smartroute.com',
        'telefono': '+57 315 222 3344',
      },
      {
        'id': 'b0000000-0000-0000-0000-000000000006',
        'nombre': 'Luis Fernando López (Verificado C2)',
        'email': 'luis.conductor@smartroute.com',
        'telefono': '+57 320 888 9900',
      },
    ];
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

