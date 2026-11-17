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

  /// Valida que un campo de texto obligatorio no esté vacío.
  static String? validateRequired(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida el formato de un número telefónico (mínimo 7 dígitos numéricos).
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'El teléfono es requerido' : null;
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return 'Ingresa un número telefónico válido (7 a 15 dígitos)';
    }
    return null;
  }

  /// Valida que la placa vehicular sea válida (mínimo 5 caracteres alfanuméricos).
  static String? validatePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La placa es obligatoria';
    }
    final cleaned = value.trim();
    if (cleaned.length < 5 || cleaned.length > 10) {
      return 'Placa inválida (debe tener entre 5 y 10 caracteres)';
    }
    return null;
  }

  /// Valida el código único de una unidad escolar (ej. BUS-01).
  static String? validateBusCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El código es obligatorio';
    }
    final cleaned = value.trim().toUpperCase();
    if (cleaned.length < 3) {
      return 'Ingresa un código de autobús válido (ej. BUS-03)';
    }
    return null;
  }

  /// Valida la capacidad de pasajeros de un autobús escolar.
  static String? validateCapacity(String? value, {int maxCapacity = 60}) {
    if (value == null || value.trim().isEmpty) {
      return 'La capacidad es obligatoria';
    }
    final numVal = int.tryParse(value.trim());
    if (numVal == null || numVal <= 0) {
      return 'Ingresa un número válido mayor a 0';
    }
    if (numVal > maxCapacity) {
      return 'La capacidad no puede exceder $maxCapacity asientos';
    }
    return null;
  }
}

