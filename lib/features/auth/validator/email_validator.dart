class EmailValidator {
  static final _emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}');
  static const allowedDomains = ['gmail.com', 'hotmail.com', 'outlook.com'];

  /// Returns null when valid, otherwise an error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es requerido';
    final v = value.trim();
    if (!_emailRegex.hasMatch(v)) return 'Correo inválido';
    final at = v.split('@');
    if (at.length != 2) return 'Correo inválido';
    final domain = at[1].toLowerCase();
    if (!allowedDomains.contains(domain)) return 'Solo se permiten @gmail.com, @hotmail.com o @outlook.com';
    return null;
  }
}
