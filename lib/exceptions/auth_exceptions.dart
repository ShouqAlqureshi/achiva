class UserNotLoggedInAuthException implements Exception {}

class EmptyFieldException implements Exception {}

class GenricException implements Exception {}

class InvalidPhoneNumberException implements Exception {
  final String message;
  InvalidPhoneNumberException([this.message = 'Oops..\nInvalid phone number']);

  @override
  String toString() => 'InvalidPhoneNumberException: $message';
}

class InvalidVerificationCodeException implements Exception {
  final String message;
  InvalidVerificationCodeException(
      [this.message = 'Oops..\nInvalid verification code']);

  @override
  String toString() => 'Oops..\nInvalidVerificationCodeException: $message';
}
