import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración centralizada del cliente Supabase para SmartRoute.
/// Gestiona la conexión local con el stack Docker, compatible con Web,
/// Windows Desktop y teléfonos físicos conectados por USB (mediante adb reverse).
class SupabaseConfig {
  /// Clave pública anónima de desarrollo local generada por Supabase CLI
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  /// URL de conexión a la API de Supabase local.
  /// 'http://127.0.0.1:54321' funciona en Web, Windows y en tu teléfono físico
  /// gracias al túnel 'adb reverse tcp:54321 tcp:54321'.
  static const String supabaseUrl = 'http://127.0.0.1:54321';

  /// Instancia global del cliente Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// Inicializa la conexión con el servidor Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: anonKey,
      debug: kDebugMode,
    );
  }
}
