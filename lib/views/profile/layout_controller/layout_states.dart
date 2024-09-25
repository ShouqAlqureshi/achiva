import '../../../core/errors/app_failures.dart';

abstract class LayoutStates {}

class InitialLayoutState extends LayoutStates {}
class CodeAutoRetrievalTimeOutOnChangeUserPhoneState extends LayoutStates {}

class PhoneNumVerifiedLoadingState extends LayoutStates {
  final bool usedWithCurrentPhoneOrNewOne;
  PhoneNumVerifiedLoadingState({required this.usedWithCurrentPhoneOrNewOne});
}
class PhoneNumVerifiedSuccessfullyState extends LayoutStates {
  final bool usedWithCurrentPhoneOrNewOne;
  PhoneNumVerifiedSuccessfullyState({required this.usedWithCurrentPhoneOrNewOne});
}
class PhoneNumVerifiedWithFailureState extends LayoutStates {
  final String message;
  final bool usedWithCurrentPhoneOrNewOne;
  PhoneNumVerifiedWithFailureState({required this.message,required this.usedWithCurrentPhoneOrNewOne});
}

class CheckOtpOfCurrentPhoneLoadingState extends LayoutStates {}
class CheckOtpOfCurrentPhoneSuccessfullyState extends LayoutStates {}
class CheckOtpOfCurrentPhoneWithFailureState extends LayoutStates {
  final String message;
  CheckOtpOfCurrentPhoneWithFailureState({required this.message});
}
class ChangeGenderStatusState extends LayoutStates {}

class SignOutSuccessfullyState extends LayoutStates {}

class ToggleGenderState extends LayoutStates {}
class ToggleBetweenFriendsAndGoalsBarState extends LayoutStates {}

class PickedUserImageSuccessfullyState extends LayoutStates {}
class PickedUserImageWithFailureState extends LayoutStates {}

class GetUserDataSuccessfullyState extends LayoutStates {}
class GetUserDataLoadingState extends LayoutStates {}
class GetUserDataWithFailureState extends LayoutStates {
  final Failure failure;
  GetUserDataWithFailureState({required this.failure});
}

class GetUserGoalsSuccessfullyState extends LayoutStates {}
class GetUserGoalsLoadingState extends LayoutStates {}
class GetUserGoalsWithFailureState extends LayoutStates {
  final Failure failure;
  GetUserGoalsWithFailureState({required this.failure});
}

class UpdateUserDataSuccessfullyState extends LayoutStates {}
class UpdateUserDataLoadingState extends LayoutStates {}
class UpdateUserDataWithFailureState extends LayoutStates {
  final String message;
  UpdateUserDataWithFailureState({required this.message});
}

class ChangeUserPhoneNumberSuccessfullyState extends LayoutStates {}
class ChangeUserPhoneNumberLoadingState extends LayoutStates {}
class ChangeUserPhoneNumberWithFailureState extends LayoutStates {
  final String message;
  ChangeUserPhoneNumberWithFailureState({required this.message});
}

class OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState extends LayoutStates {}
class OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState extends LayoutStates {
  final String message;
  OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState({required this.message});
}
class DeleteAccountSuccessfullyState extends LayoutStates {}
class DeleteAccountLoadingState extends LayoutStates {}
class DeleteAccountWithFailureState extends LayoutStates {
  final String message;
  DeleteAccountWithFailureState({required this.message});
}