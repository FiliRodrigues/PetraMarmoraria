import 'package:flutter_test/flutter_test.dart';
import 'package:petra_erp/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns null for valid email', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
      });

      test('returns error for empty email', () {
        expect(Validators.validateEmail(''), 'E-mail é obrigatório');
      });

      test('returns error for null email', () {
        expect(Validators.validateEmail(null), 'E-mail é obrigatório');
      });

      test('returns error for invalid email format', () {
        expect(Validators.validateEmail('not-an-email'), 'E-mail inválido');
        expect(Validators.validateEmail('@missing.com'), 'E-mail inválido');
        expect(Validators.validateEmail('missing@'), 'E-mail inválido');
      });
    });

    group('validatePassword', () {
      test('returns null for valid password (6+ chars)', () {
        expect(Validators.validatePassword('123456'), isNull);
      });

      test('returns error for empty password', () {
        expect(Validators.validatePassword(''), 'Senha é obrigatória');
      });

      test('returns error for null password', () {
        expect(Validators.validatePassword(null), 'Senha é obrigatória');
      });

      test('returns error for short password', () {
        expect(Validators.validatePassword('12345'),
            'A senha deve conter no mínimo 6 caracteres');
      });
    });

    group('validateRequired', () {
      test('returns null for non-empty value', () {
        expect(Validators.validateRequired('something', 'Nome'), isNull);
      });

      test('returns error for empty value', () {
        expect(Validators.validateRequired('', 'Nome'), 'Nome é obrigatório');
      });

      test('returns error for null value', () {
        expect(Validators.validateRequired(null, 'Campo'), 'Campo é obrigatório');
      });

      test('uses custom field name in error', () {
        final result = Validators.validateRequired('', 'Telefone');
        expect(result, 'Telefone é obrigatório');
      });
    });
  });
}
