class AppValidators {
  static String? requiredText(
    String? value, {
    String message = 'Campo obrigatÃƒÂ³rio.',
  }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  static String? minLength(String? value, int min, {String? message}) {
    final text = value?.trim() ?? '';

    if (text.length < min) {
      return message ?? 'Informe pelo menos $min caracteres.';
    }

    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Informe o e-mail.';
    }

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!regex.hasMatch(text)) {
      return 'Informe um e-mail vÃƒÂ¡lido.';
    }

    return null;
  }

  static String? phone(String? value) {
    final text = value?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (text.isEmpty) {
      return 'Informe o telefone.';
    }

    if (text.length < 10 || text.length > 11) {
      return 'Informe um telefone vÃƒÂ¡lido.';
    }

    return null;
  }

  static String? money(String? value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';

    if (text.isEmpty) {
      return 'Informe o valor.';
    }

    final parsed = double.tryParse(text);

    if (parsed == null || parsed <= 0) {
      return 'Informe um valor vÃƒÂ¡lido.';
    }

    return null;
  }

  static String? positiveInt(String? value) {
    final text = value?.trim() ?? '';
    final parsed = int.tryParse(text);

    if (parsed == null || parsed <= 0) {
      return 'Informe um número maior que zero.';
    }

    return null;
  }

  static String normalizeMoney(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

    return parsed.toStringAsFixed(2).replaceAll('.', ',');
  }
}
