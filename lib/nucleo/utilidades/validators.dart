class Validators {
  /// Valida que el correo no esté vacío y tenga un formato válido.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    // Expresión regular básica para correos electrónicos
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  /// Valida que la contraseña no esté vacía y tenga al menos 6 caracteres.
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }
}
