import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
  );

  static String formatCurrency(double value) {
    return _currencyFormat.format(value);
  }

  static String formatOSNumber(int? value) {
    if (value == null) return '#0000';
    return '#${value.toString().padLeft(4, '0')}';
  }

  static String formatPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7)}';
    } else if (clean.length == 10) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6)}';
    }
    return phone;
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final clean = text.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    if (clean.length <= 2) {
      formatted = '($clean';
    } else if (clean.length <= 6) {
      formatted = '(${clean.substring(0, 2)}) ${clean.substring(2)}';
    } else if (clean.length <= 10) {
      formatted = '(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6)}';
    } else {
      final end = clean.length > 11 ? 11 : clean.length;
      formatted = '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7, end)}';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final clean = text.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    if (clean.length <= 11) {
      // CPF: 000.000.000-00
      if (clean.length <= 3) {
        formatted = clean;
      } else if (clean.length <= 6) {
        formatted = '${clean.substring(0, 3)}.${clean.substring(3)}';
      } else if (clean.length <= 9) {
        formatted = '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6)}';
      } else {
        formatted = '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9)}';
      }
    } else {
      // CNPJ: 00.000.000/0000-00
      final end = clean.length > 14 ? 14 : clean.length;
      final sub = clean.substring(0, end);
      if (sub.length <= 12) {
        formatted = '${sub.substring(0, 2)}.${sub.substring(2, 5)}.${sub.substring(5, 8)}/${sub.substring(8)}';
      } else {
        formatted = '${sub.substring(0, 2)}.${sub.substring(2, 5)}.${sub.substring(5, 8)}/${sub.substring(8, 12)}-${sub.substring(12)}';
      }
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final clean = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final double value = double.parse(clean) / 100;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

