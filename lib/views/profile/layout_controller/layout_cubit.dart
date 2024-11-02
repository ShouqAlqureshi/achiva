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
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  UserModel? user;
  File? userImage;
  String? chosenGender;
  String? verificationIdOfPhoneVerify;
  bool showFriendNotGoalsOnProfile = true;
  List<GoalModel> myGoals = [];
  List<UserModel> myFriends = [];

  // Reset all data when signing out or switching accounts
  void _resetState() {
    user = null;
    userImage = null;
    chosenGender = null;
    verificationIdOfPhoneVerify = null;
    showFriendNotGoalsOnProfile = true;
    myGoals.clear();
    myFriends.clear();
    emit(InitialLayoutState());
  }

  Future<void> getUserData({bool? updateUserData}) async {
    try {
      // Always fetch fresh data to avoid stale state
      emit(GetUserDataLoadingState());
      
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(GetUserDataWithFailureState(
            failure: InvalidDataEnteredByUserFailure()));
        return;
      }

      final docSnapshot = await cloudFirestore
          .collection("Users")
          .doc(currentUser.uid)
          .get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        log("getUserData is Null");
        emit(GetUserDataWithFailureState(
            failure: InvalidDataEnteredByUserFailure()));
        return;
      }

      user = UserModel.fromJson(json: docSnapshot.data()!);
      log("User data fetched: ${docSnapshot.data()}");
      emit(GetUserDataSuccessfullyState());
    } on FirebaseException catch (e) {
      log("GetUserData error: ${e.message}");
      emit(GetUserDataWithFailureState(
          failure: await CheckInternetConnection.getStatus()
              ? InternetNotFoundFailure()
              : ServerFailure()));
    }
  }

  Future<void> pickUserImage({required ImageSource imageSource}) async {
    userImage = await AppConstants.kPickedImage(imageSource: imageSource);
    userImage != null
        ? emit(PickedUserImageSuccessfullyState())
        : emit(PickedUserImageWithFailureState());
  }

  void changeGenderStatus({required String value}) {
    chosenGender = value;
    emit(ToggleGenderState());
  }

  void toggleBetweenFriendsAndGoalsBar({required bool viewFriendsNotGoals}) {
    showFriendNotGoalsOnProfile = viewFriendsNotGoals;
    emit(ToggleBetweenFriendsAndGoalsBarState());
  }

  Future<void> getMyGoals({bool? updateData}) async {
    try {
      myGoals.clear();
      emit(GetUserGoalsLoadingState());
      
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(GetUserGoalsWithFailureState(failure: ServerFailure()));
        return;
      }

      final goalsSnapshot = await cloudFirestore
          .collection(AppStrings.kUsersCollectionName)
          .doc(currentUser.uid)
          .collection(AppStrings.kGoalsCollectionName)
          .get();

      for (var doc in goalsSnapshot.docs) {
        myGoals.add(GoalModel.fromJson(json: doc.data()));
      }
      
      emit(GetUserGoalsSuccessfullyState());
    } on FirebaseException catch (e) {
      log("GetMyGoals error: ${e.message}");
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
      
      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) {
        emit(GetUserFriendsWithFailureState(failure: ServerFailure()));
        return;
      }

      final friendsSnapshot = await cloudFirestore
          .collection(AppStrings.kUsersCollectionName)
          .doc(currentUser.uid)
          .collection(AppStrings.kFriendsCollectionName)
          .get();

      for (var doc in friendsSnapshot.docs) {
        UserModel? friend = await getUserById(userId: doc.id);
        if (friend != null) {
          myFriends.add(friend);
        }
      }

      emit(GetUserFriendsSuccessfullyState());
    } on FirebaseException catch (e) {
      log("GetMyFriends error: ${e.message}");
      emit(GetUserFriendsWithFailureState(
          failure: await CheckInternetConnection.getStatus()
              ? InternetNotFoundFailure()
              : ServerFailure()));
    }
  }

  Future<UserModel?> getUserById({required String userId}) async {
    try {
      final userDoc = await cloudFirestore
          .collection("Users")
          .doc(userId)
          .get();
          
      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromJson(json: userDoc.data()!);
      }
      return null;
    } catch (e) {
      log("GetUserById error: $e");
      return null;
    }
  }

  Future<String?> uploadImageToStorage() async {
    try {
      if (userImage == null) return null;
      
      final fileName = Uri.file(userImage!.path).pathSegments.last;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("${AppStrings.kUsersCollectionName}/$fileName");
          
      final uploadTask = await storageRef.putFile(userImage!);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      log("UploadImage error: ${e.message}");
      return null;
    }
  }

  Future<void> updateUserData({
    required String fname,
    required String lname,
    required String gender,
    required String userID,
    required String email,
  }) async {
    try {
      emit(UpdateUserDataLoadingState());
      
      String? urlOfUpdatedUserImage;
      if (userImage != null) {
        urlOfUpdatedUserImage = await uploadImageToStorage();
      }

      final updatedUser = UserModel(
        id: userID,
        fname: fname,
        lname: lname,
        email: email,
        gender: gender,
        photo: urlOfUpdatedUserImage ?? user?.photo,
        phoneNumber: user!.phoneNumber,
      );

      await cloudFirestore
          .collection(AppStrings.kUsersCollectionName)
          .doc(userID)
          .set(updatedUser.toJson());

      // Fetch updated user data
      await getUserData(updateUserData: true);
      emit(UpdateUserDataSuccessfullyState());
    } on FirebaseException catch (e) {
      log("UpdateUserData error: ${e.message}");
      emit(UpdateUserDataWithFailureState(
          message: await CheckInternetConnection.getStatus()
              ? AppStrings.kInternetLostMessage
              : AppStrings.kServerFailureMessage));
    }
  }

  Future<void> signOut({
    required bool notToEmitToState,
    required BuildContext context,
  }) async {
    try {
      // First reset all state
      _resetState();
      
      // Sign out from Firebase
      await firebaseAuth.signOut();
      
      // Clear cache
      await CacheHelper.clearCache();
      AppConstants.kUserID = null;

      // Navigate to auth screen
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PhoneNumAuthView()));

      if (!notToEmitToState) {
        emit(SignOutSuccessfullyState());
      }
    } catch (e) {
      log("SignOut error: $e");
    }
  }

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

  // Future<void> signOut(
  //     {required bool notToEmitToState, required BuildContext context}) async {
  //   Navigator.pushReplacement(
  //       context, MaterialPageRoute(builder: (_) => const PhoneNumAuthView()));
  //   await CacheHelper.clearCache();
  //   AppConstants.kUserID = null;

  //   myGoals.clear();
  //   user = null;
  //   if (notToEmitToState == false) {
  //     emit(SignOutSuccessfullyState());
  //   }
  // }

  removeFrieand({required String userId}) async {
    try {
      log("delete doc: $userId from: ${AppStrings.kUsersCollectionName}/${FirebaseAuth.instance.currentUser!.uid}/${AppStrings.kFriendsCollectionName}");
        await cloudFirestore
        .collection(AppStrings.kUsersCollectionName)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection(AppStrings.kFriendsCollectionName)
        .doc(userId)
        .delete();
        
 await cloudFirestore
        .collection(AppStrings.kUsersCollectionName)
        .doc(userId)
        .collection(AppStrings.kFriendsCollectionName)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();

    log("Document deleted");
    getMyFriends();
    } catch (e) {
      log("$e");
      emit(GetUserGoalsWithFailureState(failure: ServerFailure()));
    }
  }
}

