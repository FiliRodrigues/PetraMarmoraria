import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petra_erp/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    group('formatCurrency', () {
      test('formats zero correctly', () {
        final result = Formatters.formatCurrency(0);
        expect(result, 'R\$\u00a00,00');
      });

      test('formats positive value', () {
        final result = Formatters.formatCurrency(1500.50);
        expect(result, 'R\$\u00a01.500,50');
      });

      test('formats negative value', () {
        final result = Formatters.formatCurrency(-50.99);
        expect(result, contains('-'));
      });
    });

    group('formatOSNumber', () {
      test('formats number with padding', () {
        expect(Formatters.formatOSNumber(1), '#0001');
        expect(Formatters.formatOSNumber(42), '#0042');
        expect(Formatters.formatOSNumber(9999), '#9999');
      });

      test('returns fallback for null', () {
        expect(Formatters.formatOSNumber(null), '#0000');
      });
    });

    group('formatPhone', () {
      test('formats 11-digit phone', () {
        final result = Formatters.formatPhone('11999998888');
        expect(result, '(11) 99999-8888');
      });

      test('formats 10-digit phone', () {
        final result = Formatters.formatPhone('1133334444');
        expect(result, '(11) 3333-4444');
      });

      test('returns original for unrecognized format', () {
        final result = Formatters.formatPhone('123');
        expect(result, '123');
      });

      test('strips non-digits before formatting', () {
        final result = Formatters.formatPhone('(11) 99999-8888');
        expect(result, '(11) 99999-8888');
      });
    });
  });

  group('PhoneInputFormatter', () {
    late PhoneInputFormatter formatter;

    setUp(() {
      formatter = PhoneInputFormatter();
    });

    test('formats as user types', () {
      const oldValue = TextEditingValue.empty;
      var newValue = const TextEditingValue(
        text: '11',
        selection: TextSelection.collapsed(offset: 2),
      );
      var result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '(11');

      newValue = const TextEditingValue(
        text: '11999999999',
        selection: TextSelection.collapsed(offset: 11),
      );
      result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '(11) 99999-9999');
    });

    test('returns empty for empty input', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue.empty;
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });
  });

  group('CpfCnpjInputFormatter', () {
    late CpfCnpjInputFormatter formatter;

    setUp(() {
      formatter = CpfCnpjInputFormatter();
    });

    test('formats CPF (11 digits)', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '12345678909',
        selection: TextSelection.collapsed(offset: 11),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '123.456.789-09');
    });

    test('formats CNPJ (14 digits)', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '12345678000199',
        selection: TextSelection.collapsed(offset: 14),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '12.345.678/0001-99');
    });

    test('returns empty for empty input', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue.empty;
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });
  });

  group('CurrencyInputFormatter', () {
    late CurrencyInputFormatter formatter;

    setUp(() {
      formatter = CurrencyInputFormatter();
    });

    test('formats currency as user types', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '150050',
        selection: TextSelection.collapsed(offset: 6),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, 'R\$\u00a01.500,50');
    });

    test('returns empty for empty input', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue.empty;
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });
  });
}
