import 'dart:developer';
import 'package:achiva/core/constants/extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/components/awesome_dialog_widget.dart';
import '../../core/components/btn_widgets.dart';
import '../../core/components/drop_down_button.dart';
import '../../core/components/showSnackBar.dart';
import '../../core/components/textField_widget.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import 'layout_controller/layout_cubit.dart';
import 'layout_controller/layout_states.dart';

class EditProfileScreen extends StatefulWidget {
  final LayoutCubit layoutCubit;

  const EditProfileScreen({super.key, required this.layoutCubit});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  bool isFormSubmited = false;

  void setUserDataToTextFields() {
    widget.layoutCubit.userImage = null;
    _fnameController.text = widget.layoutCubit.user!.fname;
    _lnameController.text = widget.layoutCubit.user!.lname;
    _emailController.text = widget.layoutCubit.user!.email;
    widget.layoutCubit.chosenGender = widget.layoutCubit.user!.gender;
  }

  @override
  void initState() {
    setUserDataToTextFields();
    super.initState();
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    widget.layoutCubit.chosenGender = null;
    widget.layoutCubit.userImage = null;
    super.dispose();
  }

  List<String> emails = [];

  Future<bool> checkIfEmailExists(String email) async {
    try {
      var response = await FirebaseFirestore.instance.collection("Users").get();
      for (var email in response.docs) {
        emails.add(email.data()["email"].toString().toLowerCase());
      }
      return emails.contains(email.toLowerCase());
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<void> updateUserData() async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection("Users")
          .doc(AppConstants.kUserID ?? widget.layoutCubit.user!.id);

      // First, get the current user document
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Get current data
      final currentData = userDoc.data() as Map<String, dynamic>;

      // Create update map with only the profile fields
      final Map<String, dynamic> updateData = {
        'fname': _fnameController.text.trim(),
        'lname': _lnameController.text.trim(),
        'gender': widget.layoutCubit.chosenGender!,
        'email': _emailController.text.trim(),
      };

      // If there's a new photo, add it to the update data
      if (widget.layoutCubit.userImage != null) {
        // Add your image upload logic here and update the photo field
        // updateData['photo'] = uploadedPhotoUrl;
      }

      // Update only the specified fields using set with merge
      await userRef.set(updateData, SetOptions(merge: true));

      // Notify success
      widget.layoutCubit.emit(UpdateUserDataSuccessfullyState());
    } catch (e) {
      widget.layoutCubit.emit(UpdateUserDataWithFailureState(message: e.toString()));
    }
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Edit Profile"),
      ),
      body: Stack(
        children: [
          Form(
            key: formState,
            child: ListView(
              padding: AppConstants.kScaffoldPadding.copyWith(bottom: 24),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      BlocBuilder<LayoutCubit, LayoutStates>(
                        buildWhen: (past, currentState) =>
                            currentState is PickedUserImageSuccessfullyState,
                        builder: (context, state) {
                          if (widget.layoutCubit.userImage != null) {
                            return CircleAvatar(
                              radius: 64,
                              backgroundImage: FileImage(widget.layoutCubit.userImage!),
                            );
                          } else if (widget.layoutCubit.user!.photo != null) {
                            return CircleAvatar(
                              radius: 64,
                              backgroundImage: NetworkImage(widget.layoutCubit.user!.photo!),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(Icons.person, size: 60, color: Colors.grey),
                            );
                          }
                        },
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.kLightGrey,
                        child: InkWell(
                          onTap: () {
                            showImageSourceDialog(
                              context: context,
                              pickCameraImage: () =>
                                  widget.layoutCubit.pickUserImage(imageSource: ImageSource.camera),
                              pickGalleryImage: () =>
                                  widget.layoutCubit.pickUserImage(imageSource: ImageSource.gallery),
                            );
                          },
                          child: Icon(Icons.edit, color: AppColors.kWhiteColor),
                        ),
                      ),
                    ],
                  ),
                ),
                24.vrSpace,
                TextFieldWidget(
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "First Name is required";
                    } else if (val.contains(" ")) {
                      return "whitespace is not allowed in First Name";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  controller: _fnameController,
                  hint: "First Name",
                  prefixIconData: Icons.account_circle,
                ),
                TextFieldWidget(
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Last Name is required";
                    } else if (val.contains(" ")) {
                      return "whitespace is not allowed in Last Name";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  controller: _lnameController,
                  hint: "Last Name",
                  prefixIconData: Icons.account_circle,
                ),
                TextFieldWidget(
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Email is required";
                    }
                    if (!isValidEmail(val)) {
                      return "Please enter a valid email address";
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  controller: _emailController,
                  hint: "Email",
                  prefixIconData: Icons.email,
                ),
                BlocBuilder<LayoutCubit, LayoutStates>(
                  buildWhen: (past, current) => current is ChangeGenderStatusState,
                  builder: (context, state) {
                    return DropDownBtnWidget(
                      items: const ["male", "female"],
                      hint: "Choose your gender",
                      value: widget.layoutCubit.chosenGender,
                      onChanged: (value) {
                        setState(() {
                          widget.layoutCubit.changeGenderStatus(value: value);
                        });
                      },
                    );
                  },
                ),
                8.vrSpace,
                BlocConsumer<LayoutCubit, LayoutStates>(
                  listenWhen: (past, current) =>
                      current is UpdateUserDataWithFailureState ||
                      current is UpdateUserDataSuccessfullyState ||
                      current is UpdateUserDataLoadingState,
                  listener: (context, state) {
                    if (state is UpdateUserDataWithFailureState) {
                      showSnackBarWidget(
                          message: state.message, successOrNot: false, context: context);
                    }
                    if (state is UpdateUserDataSuccessfullyState) {
                      showSnackBarWidget(
                          message: "Your information is updated successfully",
                          successOrNot: true,
                          context: context);
                      Navigator.pop(context);
                    }
                  },
                  builder: (context, state) => state is UpdateUserDataLoadingState
                      ? const Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(),
                        )
                      : BtnWidget(
                          minWidth: double.infinity,
                          onTap: () async {
                            if (_fnameController.text.isNotEmpty &&
                                _lnameController.text.isNotEmpty &&
                                _emailController.text.isNotEmpty &&
                                widget.layoutCubit.chosenGender == null) {
                              showSnackBarWidget(
                                  message: "Please, Choose your gender",
                                  successOrNot: false,
                                  context: context);
                            } else if (await checkIfEmailExists(_emailController.text) &&
                                _emailController.text != widget.layoutCubit.user!.email) {
                              showSnackBarWidget(
                                  message: "Email already exists",
                                  successOrNot: false,
                                  context: context);
                            } else {
                              if (formState.currentState!.validate()) {
                                await updateUserData();
                              }
                            }
                          },
                          title: state is UpdateUserDataLoadingState
                              ? "Update data loading"
                              : "Update",
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}