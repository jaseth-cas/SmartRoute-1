class AdminRouteValidator {
  // Expresión regular: solo permite letras, números, espacios, puntos, comas y guiones.
  static final RegExp _validCharsRegExp = RegExp(r'^[a-zA-Z0-9\s.,áéíóúÁÉÍÓÚñÑ-]+$');

  /// Valida los datos ingresados al crear o editar una ruta en el módulo de Administrador.
  /// Retorna un mensaje de error si algún campo es inválido, o null si todos los datos son correctos.
  static String? validateNewRouteData({
    required String? name,
    required String? origin,
    required String? destination,
  }) {
    // Validar si algún campo está vacío
    if (name == null || name.trim().isEmpty || 
        origin == null || origin.trim().isEmpty || 
        destination == null || destination.trim().isEmpty) {
      return 'Todos los campos son obligatorios';
    }
    
    // Validar longitud mínima (al menos 4 caracteres por campo)
    if (name.trim().length < 4 || origin.trim().length < 4 || destination.trim().length < 4) {
      return 'Cada campo debe tener al menos 4 caracteres';
    }
    
    // Validar longitud máxima (evitar desbordamientos)
    if (name.trim().length > 50 || origin.trim().length > 50 || destination.trim().length > 50) {
      return 'Los campos no pueden exceder los 50 caracteres';
    }
    
    // Validar que no haya caracteres especiales extraños
    if (!_validCharsRegExp.hasMatch(name) || 
        !_validCharsRegExp.hasMatch(origin) || 
        !_validCharsRegExp.hasMatch(destination)) {
      return 'No se permiten caracteres especiales (@, #, \$, etc.)';
    }

    // Retorno exitoso (Happy path)
    return null;
  }

  /// Valida los datos ingresados al crear o editar una parada en el módulo de Administrador.
  /// Retorna un mensaje de error si algún campo es inválido, o null si todos los datos son correctos.
  static String? validateNewStopData({
    required String? name,
    required String? lat,
    required String? lng,
  }) {
    if (name == null || name.trim().isEmpty || 
        lat == null || lat.trim().isEmpty || 
        lng == null || lng.trim().isEmpty) {
      return 'Todos los campos son obligatorios';
    }

    if (name.trim().length < 4) {
      return 'El nombre de la parada debe tener al menos 4 caracteres';
    }

    if (name.trim().length > 50) {
      return 'El nombre de la parada no puede exceder los 50 caracteres';
    }

    if (!_validCharsRegExp.hasMatch(name)) {
      return 'El nombre no permite caracteres especiales (@, #, \$, etc.)';
    }

    final double? parsedLat = double.tryParse(lat.trim());
    if (parsedLat == null || parsedLat.isNaN || parsedLat < -90 || parsedLat > 90) {
      return 'Latitud inválida. Debe ser un número entre -90 y 90';
    }

    final double? parsedLng = double.tryParse(lng.trim());
    if (parsedLng == null || parsedLng.isNaN || parsedLng < -180 || parsedLng > 180) {
      return 'Longitud inválida. Debe ser un número entre -180 y 180';
    }

    return null;
  }
}
