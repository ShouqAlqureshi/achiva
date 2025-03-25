import 'package:achiva/views/auth/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators Logic Tests', () {
    late Validators logic;
    // late FakeFirebaseFirestore fakeFirestore;
    // fakeFirestore = FakeFirebaseFirestore();
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
        expect(logic.validateEmail('invalid-email'),
            'Please enter a valid email address');
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
    group("isEmailUnique tests", () {
      test('testing isEmailUnique with a unique email returns true', () async {
        
        // await fakeFirestore
        //     .collection('Users')
        //     .add({'email': 'existinguser@gmail.com'});

        // Act
        // bool result =
        //     await logic.isEmailUnique("fahad@gmail.com", fakeFirestore);

        // // Assert
        // expect(result, true, reason: "fahad@gmail.com should be unique");
      });

      test('testing isEmailUnique can handle case sensitivity comparison',
          () async {
     
        // await fakeFirestore
        //     .collection('Users')
        //     .add({'email': 'shooqalsu@gmail.com'});

    
        // bool result =
        //     await logic.isEmailUnique("Shooqalsu@gmail.com", fakeFirestore);

     
        // expect(result, true,
        //     reason:
        //         "Shooqalsu@gmail.com should be unique due to case sensitivity");
      });

      test('testing isEmailUnique with a non-unique email returns false',
          () async {

        // await fakeFirestore
        //     .collection('Users')
        //     .add({'email': 'shooqalsu@gmail.com'});

        // bool result =
        //     await logic.isEmailUnique("shooqalsu@gmail.com", fakeFirestore);

        // expect(result, false,
        //     reason: "shooqalsu@gmail.com should not be unique");
      });
    });
        group('validatePhoneNum tests', () {
      test('Empty phone number returns error message', () {
        expect(logic.validatePhoneNum(''), "Phone number required");
        expect(logic.validatePhoneNum(null), "Phone number required");
      });

      test('Invalid phone number format returns error message', () {
        expect(logic.validatePhoneNum('553175533'),
            "Invalid phone number ex.+966531567889");
      });

      test('Valid phone number returns null error massage', () {
        expect(logic.validatePhoneNum('+966531833221'), null);
      });
    });
        group('validateCode tests', () {
      test('Empty Code field returns error message', () {
        expect(logic.validateCode(''), "Code field is required");
        expect(logic.validateCode(null), "Code field is required");
      });

      test('Invalid Code format returns error message', () {
        expect(logic.validateCode('1234'),
            "code must be 6 digits");
      });

      test('Valid Code returns null error massage', () {
        expect(logic.validateCode('123456'), null);
      });
    });
  });
}
