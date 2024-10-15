import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/constants.dart';
import '../../../core/constants/strings.dart';
import '../../../core/errors/app_failures.dart';
import '../../../core/network/cache_network.dart';
import '../../../core/network/check_internet_connection.dart';
import '../../../models/goal_model.dart';
import '../../../models/user_model.dart';
import '../../auth/phone_num_authview.dart';
import 'layout_states.dart';

class LayoutCubit extends Cubit<LayoutStates> {
  LayoutCubit() : super(InitialLayoutState());

  static LayoutCubit getInstance(BuildContext context) =>
      BlocProvider.of<LayoutCubit>(context);

  final FirebaseFirestore cloudFirestore = FirebaseFirestore.instance;
  UserModel? user;

  Future<void> getUserData({bool? updateUserData}) async {
    try {
      if (user == null || updateUserData != null) {
        emit(GetUserDataLoadingState());
        await FirebaseFirestore.instance
            .collection("Users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((e) {
          log(FirebaseAuth.instance.currentUser!.uid);

          if (e.data() != null) {
            user = UserModel.fromJson(json: e.data()!);

            log(e.data().toString());
            emit(GetUserDataSuccessfullyState());
          } else {
            log("getUserData is Null");
            emit(GetUserDataWithFailureState(
                failure: InvalidDataEnteredByUserFailure()));
          }
        });
      }
    } on FirebaseException catch (e) {
      emit(GetUserDataWithFailureState(
          failure: await CheckInternetConnection.getStatus()
              ? InternetNotFoundFailure()
              : ServerFailure()));
    }
  }

  File? userImage;

  Future<void> pickUserImage({required ImageSource imageSource}) async {
    userImage = await AppConstants.kPickedImage(imageSource: imageSource);
    userImage != null
        ? emit(PickedUserImageSuccessfullyState())
        : emit(PickedUserImageWithFailureState());
  }

  String? chosenGender;

  void changeGenderStatus({required String value}) {
    chosenGender = value;
    emit(ToggleGenderState());
  }

  bool showFriendNotGoalsOnProfile = true;

  void toggleBetweenFriendsAndGoalsBar({required bool viewFriendsNotGoals}) {
    showFriendNotGoalsOnProfile = viewFriendsNotGoals;
    emit(ToggleBetweenFriendsAndGoalsBarState());
  }

  List<GoalModel> myGoals = [];
  List<UserModel> myFriends = [];
  Future<void> getMyGoals({bool? updateData}) async {
    try {
      myGoals.clear(); // TODO: to get new data
      emit(GetUserGoalsLoadingState());
      await cloudFirestore
          .collection(AppStrings.kUsersCollectionName)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection(AppStrings.kGoalsCollectionName)
          .get()
          .then((data) {
        for (var item in data.docs) {
          myGoals.add(GoalModel.fromJson(json: item.data()));
        }
      });
      emit(GetUserGoalsSuccessfullyState());
    } on FirebaseException catch (e) {
      emit(GetUserGoalsWithFailureState(
          failure: await CheckInternetConnection.getStatus()
              ? InternetNotFoundFailure()
              : ServerFailure()));
    }
  }

  Future<List<GoalModel>> getGoalsByUserId({required String userId}) async {
    try {
      List<GoalModel> goals = [];
      var snapshot = await cloudFirestore
          .collection(AppStrings.kUsersCollectionName)
          .doc(userId)
          .collection(AppStrings.kGoalsCollectionName)
          .get();
      if (snapshot.docs.isEmpty) {
        return [];
      }

      for (var item in snapshot.docs) {
        GoalModel goal = GoalModel.fromJson(json: item.data());
        // this also can be done by where clause in the firebase query
        if (goal.visibility) {
          goals.add(goal);
        }
      }

      return goals;
    } on FirebaseException catch (e) {
      throw Exception("somthing whent wrong");
    }
  }

  Future<void> getMyFriends({bool? updateData}) async {
    try {
      myFriends.clear();
      emit(GetUserFriendsLoadingState());
      await cloudFirestore
          .collection(AppStrings.kUsersCollectionName)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection(AppStrings.kFriendsCollectionName)
          .get()
          .then((data) async {
        for (var item in data.docs) {
          UserModel? user = await getUserById(userId: item.id);
          if (user != null) {
            myFriends.add(user);
          }
        }
      });

      emit(GetUserFriendsSuccessfullyState());
    } on FirebaseException catch (e) {
      log("getMyFriends Exception : $e");
      emit(GetUserFriendsWithFailureState(
          failure: await CheckInternetConnection.getStatus()
              ? InternetNotFoundFailure()
              : ServerFailure()));
    }
  }

  Future<UserModel?> getUserById({required String userId}) async {
    var snapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromJson(json: snapshot.data()!);
    } else {
      return null;
    }
  }

  Future<String?> uploadImageToStorage() async {
    try {
      TaskSnapshot taskSnapshot = await FirebaseStorage.instance
          .ref()
          .child(
              "${AppStrings.kUsersCollectionName}/${Uri.file(userImage!.path).pathSegments.last}")
          .putFile(userImage!);
      return await taskSnapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      return null;
    }
  }

  Future<void> updateUserData(
      {required String fname,
      required String lname,
      required String gender,
      required String userID,
      required String email}) async {
    try {
      emit(UpdateUserDataLoadingState());
      String? urlOfUpdatedUserImage;
      if (userImage != null) {
        urlOfUpdatedUserImage = await uploadImageToStorage();
      }
      UserModel model = UserModel(
        id: userID,
        fname: fname,
        lname: lname,
        email: email,
        gender: gender,
        photo: urlOfUpdatedUserImage ?? user!.photo,
        phoneNumber: user!.phoneNumber,
        /*         streak: user!.streak,
          productivity: user!.productivity*/
      );
      await FirebaseFirestore.instance
          .collection(AppStrings.kUsersCollectionName)
          .doc(userID)
          .set(model.toJson());
      await getUserData(updateUserData: true);
      emit(UpdateUserDataSuccessfullyState());
    } on FirebaseException catch (e) {
      emit(UpdateUserDataWithFailureState(
          message: await CheckInternetConnection.getStatus()
              ? AppStrings.kInternetLostMessage
              : AppStrings.kServerFailureMessage));
    }
  }

  String? verificationIdOfPhoneVerify;

  Future<void> verifyPhoneNum(
      {required String phoneNumber,
      required bool usedWithCurrentPhoneOrNewOne}) async {
    try {
      emit(PhoneNumVerifiedLoadingState(
          usedWithCurrentPhoneOrNewOne: usedWithCurrentPhoneOrNewOne));
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          emit(PhoneNumVerifiedWithFailureState(
              usedWithCurrentPhoneOrNewOne: usedWithCurrentPhoneOrNewOne,
              message: "Error, ${e.code.replaceAll("-", " ")}"));
        },
        codeSent: (String verificationId, int? resendToken) {
          verificationIdOfPhoneVerify = verificationId;
          emit(PhoneNumVerifiedSuccessfullyState(
              usedWithCurrentPhoneOrNewOne: usedWithCurrentPhoneOrNewOne));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verificationIdOfPhoneVerify = verificationId;
          emit(CodeAutoRetrievalTimeOutOnChangeUserPhoneState());
        },
      );
    } on FirebaseException catch (e) {
      emit(PhoneNumVerifiedWithFailureState(
          usedWithCurrentPhoneOrNewOne: usedWithCurrentPhoneOrNewOne,
          message: "Error, ${e.code.replaceAll("-", " ")}"));
    }
  }

  void checkOtpOfCurrentPhone({required String code}) async {
    try {
      emit(CheckOtpOfCurrentPhoneLoadingState());
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationIdOfPhoneVerify!, smsCode: code);
      await firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
      emit(CheckOtpOfCurrentPhoneSuccessfullyState());
    } on FirebaseException catch (e) {
      emit(CheckOtpOfCurrentPhoneWithFailureState(
          message: "Error, ${e.code.replaceAll("-", " ")}"));
    }
  }

  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<void> changeUserPhoneNumber(
      {required String pinCode, required String phoneNumber}) async {
    try {
      emit(ChangeUserPhoneNumberLoadingState());
      await firebaseAuth.currentUser!
          .updatePhoneNumber(PhoneAuthProvider.credential(
        verificationId: verificationIdOfPhoneVerify!,
        smsCode: pinCode,
      ));
      await updateUserPasswordOnDatabase(phone: phoneNumber);
      emit(ChangeUserPhoneNumberSuccessfullyState());
    } on FirebaseException catch (e) {
      debugPrint("Code : ${e.code}");
      emit(ChangeUserPhoneNumberWithFailureState(
          message: e.code.replaceAll("-", " ")));
    }
  }

  Future<void> updateUserPasswordOnDatabase({required String phone}) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppStrings.kUsersCollectionName)
          .doc(CacheHelper.getString(key: AppStrings.kUserIDName) ??
              AppConstants.kUserID!)
          .update({"phoneNumber": phone});
      user!.phoneNumber = phone;
      emit(GetUserDataSuccessfullyState());
    } on FirebaseException catch (e) {
      debugPrint(
          "Error while updating userPhoneNumber on Firestore, ${e.code}");
    }
  }

  void sendOtpForPhoneForDeletingAccount() async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: user!.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          emit(DeleteAccountWithFailureState(
              message: "Error, ${e.code.replaceAll("-", " ")}"));
        },
        codeSent: (String verificationId, int? resendToken) {
          verificationIdOfPhoneVerify = verificationId;
          emit(OtpSentToPhoneWhileDeletingPhoneNumberSuccessfullyState());
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verificationIdOfPhoneVerify = verificationId;
          emit(CodeAutoRetrievalTimeOutOnChangeUserPhoneState());
        },
      );
    } on FirebaseException catch (e) {
      emit(OtpSentToPhoneWhileDeletingPhoneNumberWithFailureState(
          message: e.code.replaceAll("-", " ")));
    }
  }

  Future<void> deleteAccount({required String pinCode, context}) async {
    try {
      emit(DeleteAccountLoadingState());
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationIdOfPhoneVerify!, smsCode: pinCode);
      await firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
      User? currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        String userID = currentUser.uid;
        await currentUser.delete();
        await cloudFirestore
            .collection(AppStrings.kUsersCollectionName)
            .doc(userID)
            .delete();
        await signOut(notToEmitToState: true, context: context);
        emit(DeleteAccountSuccessfullyState());
      }
    } on FirebaseException catch (e) {
      emit(DeleteAccountWithFailureState(
          message: "Error, ${e.code.replaceAll("-", " ")}"));
    }
  }

  Future<void> signOut(
      {required bool notToEmitToState, required BuildContext context}) async {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const PhoneNumAuthView()));
    await CacheHelper.clearCache();
    AppConstants.kUserID = null;

    myGoals.clear();
    user = null;
    if (notToEmitToState == false) {
      emit(SignOutSuccessfullyState());
    }
  }

  removeFrieand({required String userId}) async {
    try {
      await cloudFirestore
          .collection(AppStrings.kUsersCollectionName)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection(AppStrings.kFriendsCollectionName)
          .doc(userId)
          .delete()
          .then(
        (doc) {
          log("Document deleted");
          getMyFriends();
        },
        onError: (e) {
          log("Error updating document $e");
          emit(GetUserGoalsWithFailureState(failure: ServerFailure()));
        },
      );
    } catch (e) {
      log("$e");
      emit(GetUserGoalsWithFailureState(failure: ServerFailure()));
    }
  }
}
