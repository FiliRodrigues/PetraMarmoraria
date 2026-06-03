class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  /// E-mail opcional: vazio passa; se preenchido, precisa ser válido.
  static String? validateEmailOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailRegExp.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'A senha deve conter no mínimo 6 caracteres';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  /// Telefone obrigatório com 10 (fixo) ou 11 (celular) dígitos.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone inválido (use DDD + número)';
    }
    return null;
  }

  /// Telefone opcional: vazio passa; se preenchido, valida o formato.
  static String? validatePhoneOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return validatePhone(value);
  }

  /// Valor monetário obrigatório e maior que zero.
  static String? validateMoney(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return '$fieldName inválido';
    }
    if (parsed <= 0) {
      return 'Insira um valor maior que zero';
    }
    return null;
  }

  /// Número opcional que não pode ser negativo (estoque, quantidades).
  /// Vazio passa (assume 0); se preenchido, precisa ser numérico e >= 0.
  static String? validateNonNegativeOptional(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return '$fieldName inválido';
    }
    if (parsed < 0) {
      return '$fieldName não pode ser negativo';
    }
    return null;
  }

  /// CPF (11) ou CNPJ (14) opcional com checagem de dígitos verificadores.
  static String? validateCpfCnpj(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return _isValidCpf(digits) ? null : 'CPF inválido';
    }
    if (digits.length == 14) {
      return _isValidCnpj(digits) ? null : 'CNPJ inválido';
    }
    return 'CPF/CNPJ inválido';
  }

  static bool _isValidCpf(String cpf) {
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    final d = cpf.split('').map(int.parse).toList();
    int calc(int len) {
      var sum = 0;
      for (var i = 0; i < len; i++) {
        sum += d[i] * (len + 1 - i);
      }
      final r = (sum * 10) % 11;
      return r == 10 ? 0 : r;
    }

    return calc(9) == d[9] && calc(10) == d[10];
  }

  static bool _isValidCnpj(String cnpj) {
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) return false;
    final d = cnpj.split('').map(int.parse).toList();
    int calc(int len) {
      final weights = len == 12
          ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
          : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      var sum = 0;
      for (var i = 0; i < len; i++) {
        sum += d[i] * weights[i];
      }
      final r = sum % 11;
      return r < 2 ? 0 : 11 - r;
    }

    return calc(12) == d[12] && calc(13) == d[13];
  }
}
