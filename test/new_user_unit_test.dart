import 'package:achiva/views/auth/validators.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('Validators Logic Tests', () {
    late Validators logic;

    setUp(() {
      logic = Validators();
    });

    group('isValidEmail tests', () {
      test('Valid email returns true', () {
        expect(logic.isValidEmail('test@gmail.com'), true);
        expect(logic.isValidEmail('443200473@example.co.uk'), true);
      });

      test('Invalid email returns false', () {
        expect(logic.isValidEmail('invalid-email'), false);
        expect(logic.isValidEmail('missing@tld'), false);
        expect(logic.isValidEmail('@missinguser.com'), false);
      });
    });

    group('validateEmail tests', () {
      test('Empty email returns error message', () {
        expect(logic.validateEmail(''), 'Email is required');
        expect(logic.validateEmail(null), 'Email is required');
      });

      test('Invalid email format returns error message', () {
        expect(logic.validateEmail('invalid-email'), 'Please enter a valid email address');
      });

      test('Valid email returns null error massage', () {
        expect(logic.validateEmail('valid@email.com'), null);
      });
    });
group('isNotValidPhoneNumber tests', () {
      test('Invalid phone number returns true', () {
        expect(logic.isNotValidPhoneNumber('+9665315'), true);
        expect(logic.isNotValidPhoneNumber('+9665167891011345'), true);
         expect(logic.isNotValidPhoneNumber('+96631833221'), true);
      });

      test('valid phone number returns false', () {
        expect(logic.isNotValidPhoneNumber('+966531833221'), false);
      });

      test('valid phone number with no + returns true', () {
        expect(logic.isNotValidPhoneNumber('966531833221'), true);
      });
    });
    
  });
}