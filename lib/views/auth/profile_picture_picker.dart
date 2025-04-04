import 'dart:developer' show log;
import 'dart:io';
import 'dart:typed_data';
import 'package:achiva/views/onbording/onbording.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePicturePicker extends StatefulWidget {
  const ProfilePicturePicker({super.key});

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  XFile? _imageFile;
  String? imageLink;
  bool isFormSubmitted = false;
  final ImagePicker _picker = ImagePicker();
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      isFormSubmitted = true;
    });

    final usercollection = FirebaseFirestore.instance
        .collection("Users")
        .doc(FirebaseAuth.instance.currentUser!.uid);
    final datatosave =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    _showLoadingDialog();

    try {
      String photoUrl;

      if (_imageFile != null) {
        // Upload selected image
        final uploadTask = await FirebaseStorage.instance
            .ref()
            .child("Users/${Uri.file(_imageFile!.path).pathSegments.last}")
            .putFile(File(_imageFile!.path));

        photoUrl = await uploadTask.ref.getDownloadURL();
      } else {
        // Upload default image directly from asset bytes
        final ByteData data = await rootBundle.load('lib/images/chicken.png');
        final bytes = data.buffer.asUint8List();

        // Upload bytes directly
        final uploadTask = await FirebaseStorage.instance
            .ref()
            .child(
                "Users/default_${FirebaseAuth.instance.currentUser!.uid}_chicken.png")
            .putData(bytes, SettableMetadata(contentType: 'image/png'));

        photoUrl = await uploadTask.ref.getDownloadURL();
      }

      // Add the photo URL to the data
      datatosave.addAll({
        "photo": photoUrl,
        'id': FirebaseAuth.instance.currentUser!.uid,
      });

      log(datatosave.toString());
      await usercollection.set(datatosave);

      Navigator.of(context).pop(); // Dismiss loading dialog
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => Onbording(),
        ),
        (route) => false,
      );
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      log("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile photo selection",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
          textAlign: TextAlign.start,
        ),
        toolbarHeight: 100,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 30, 12, 48),
                Color.fromARGB(255, 77, 64, 98),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 30, 12, 48),
              Color.fromARGB(255, 77, 64, 98),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.5),
                    child: Container(
                      width: 350,
                      height: 350,
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _imageFile == null
                              ? CircleAvatar(
                                  radius: 80,
                                  backgroundColor: Colors.grey[200],
                                  child: ClipOval(
                                    child: Image.asset(
                                      'lib/images/chicken.png',
                                      fit: BoxFit.cover,
                                      width: 160,
                                      height: 160,
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 80,
                                  backgroundImage:
                                      FileImage(File(_imageFile!.path)),
                                ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 30, 12, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => _showImageSourceDialog(context),
                            child: const Text(
                              'Add Profile Picture',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 30, 12, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      await _uploadImage();
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Select image source',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
            child: const Text(
              'Gallery',
              style: TextStyle(color: Color.fromARGB(255, 30, 12, 48)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
