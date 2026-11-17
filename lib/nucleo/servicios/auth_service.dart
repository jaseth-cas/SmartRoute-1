import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';

/// Servicio encargado de la comunicación con Supabase Auth y la tabla de `perfiles`.
class AuthService {
  final SupabaseClient? _injectedClient;
  final http.Client? _injectedHttpClient;

  AuthService({
    SupabaseClient? supabaseClient,
    http.Client? httpClient,
  })  : _injectedClient = supabaseClient,
        _injectedHttpClient = httpClient;

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
    final cleanedId = userId.trim();
    if (cleanedId.isEmpty) {
      throw ArgumentError('El ID de usuario es obligatorio para actualizar el perfil.');
    }

    final updates = <String, dynamic>{};
    if (nombre != null && nombre.trim().isNotEmpty) updates['nombre'] = nombre.trim();
    if (email != null && email.trim().isNotEmpty) updates['email'] = email.trim();
    if (telefono != null) updates['telefono'] = telefono.trim();

    if (updates.isEmpty) return;

    final updated = await _supabase
        .from('perfiles')
        .update(updates)
        .eq('id', cleanedId)
        .select('id')
        .timeout(const Duration(seconds: 5));

    if ((updated as List).isEmpty) {
      if (updates.containsKey('email') && updates.containsKey('nombre')) {
        await _supabase.from('perfiles').upsert(
          {
            'id': cleanedId,
            'nombre': updates['nombre'],
            'email': updates['email'],
            'telefono': updates['telefono'] ?? '',
            'rol': 'student',
          },
          onConflict: 'id',
        ).timeout(const Duration(seconds: 5));
      } else {
        throw StateError(
          'No se encontró el perfil ($cleanedId) en PostgreSQL para actualizar.',
        );
      }
    }
  }

  /// Obtiene la lista de conductores disponibles registrados en el sistema
  Future<List<Map<String, dynamic>>> getAvailableDrivers() async {
    try {
      final data = await _supabase
          .from('perfiles')
          .select('id, nombre, email, telefono')
          .eq('rol', 'driver')
          .order('nombre', ascending: true)
          .timeout(const Duration(seconds: 4));
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error obteniendo conductores: $e');
      return [];
    }
  }

  /// Registra una nueva cuenta de conductor en Supabase Auth sin cerrar ni reemplazar
  /// la sesión activa del transportista (Owner) y asegura su perfil en `public.perfiles`.
  Future<Map<String, dynamic>?> registerDriverProfile({
    required String nombre,
    required String email,
    String? telefono,
    String password = 'Password123!',
  }) async {
    final cleanName = nombre.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = telefono?.trim() ?? '';

    if (cleanName.isEmpty || Validators.validateEmail(cleanEmail) != null) {
      throw ArgumentError('Nombre y correo válido son obligatorios.');
    }

    try {
      final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/signup');
      final postFuture = _injectedHttpClient != null
          ? _injectedHttpClient.post(
              uri,
              headers: {
                'apikey': SupabaseConfig.anonKey,
                'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'email': cleanEmail,
                'password': password,
                'data': {
                  'nombre': cleanName,
                  'rol': 'driver',
                },
              }),
            )
          : http.post(
              uri,
              headers: {
                'apikey': SupabaseConfig.anonKey,
                'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'email': cleanEmail,
                'password': password,
                'data': {
                  'nombre': cleanName,
                  'rol': 'driver',
                },
              }),
            );
      final response = await postFuture.timeout(const Duration(seconds: 6));

      String? createdUserId;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final userObj = decoded['user'] as Map<String, dynamic>?;
        createdUserId = (userObj?['id'] ?? decoded['id'])?.toString();
      } else {
        // Si ya existía en Auth, intentar localizarlo por email en perfiles
        final existing = await _supabase
            .from('perfiles')
            .select('id, nombre, email, telefono')
            .eq('email', cleanEmail)
            .maybeSingle()
            .timeout(const Duration(seconds: 4));
        if (existing != null) {
          return existing;
        }
        debugPrint(
          'Signup conductor HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      if (createdUserId == null || createdUserId.isEmpty) return null;

      final profilePayload = {
        'id': createdUserId,
        'nombre': cleanName,
        'email': cleanEmail,
        'rol': 'driver',
        'telefono': cleanPhone.isNotEmpty ? cleanPhone : null,
      };

      await _supabase
          .from('perfiles')
          .upsert(profilePayload)
          .timeout(const Duration(seconds: 4));

      return {
        'id': createdUserId,
        'nombre': cleanName,
        'email': cleanEmail,
        'telefono': cleanPhone,
      };
    } catch (e) {
      debugPrint('Error registrando conductor: $e');
      rethrow;
    }
  }

  /// Obtiene los datos del perfil del usuario autenticado (nombre y rol)
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('perfiles')
          .select('id, nombre, email, rol, telefono')
          .eq('id', userId)
          .maybeSingle();
      return data;
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST obteniendo perfil [${e.code}]: ${e.message}');
      return null;
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

