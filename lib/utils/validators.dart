class Validators {
  static String? notEmpty(String? value, String field) {
    if (value == null || value.isEmpty) {
      return 'El campo $field no puede quedar vacío';
    }
    return null;
  }

// Agrega más validaciones personalizadas según lo necesites
}

