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
    
    // Validar que no haya caracteres especiales extraños
    if (!_validCharsRegExp.hasMatch(name) || 
        !_validCharsRegExp.hasMatch(origin) || 
        !_validCharsRegExp.hasMatch(destination)) {
      return 'No se permiten caracteres especiales (@, #, $, etc.)';
    }

    // Retorno exitoso (Happy path)
    return null;
  }
}
