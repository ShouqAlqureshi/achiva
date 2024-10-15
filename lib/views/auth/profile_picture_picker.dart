import 'dart:io';
import 'dart:developer' show log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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

    // Show the loading dialog
    _showLoadingDialog();

    try {
      String photoUrl;

      // If the user selected an image, upload it
      if (_imageFile != null) {
        final uploadTask = await FirebaseStorage.instance
            .ref()
            .child("Users/${Uri.file(_imageFile!.path).pathSegments.last}")
            .putFile(File(_imageFile!.path));

        photoUrl = await uploadTask.ref.getDownloadURL();
        debugPrint(photoUrl);
         datatosave.addAll({
        "photo": photoUrl,
        'id': FirebaseAuth.instance.currentUser!.uid,
      });
      } else {
        // Use the default 'chicken.png' photo
        photoUrl =
            "https://firebasestorage.googleapis.com/gs://achiva444.appspot.com/defaultPictures/chicken.png";
             datatosave.addAll({
        // "photo": photoUrl,
        'id': FirebaseAuth.instance.currentUser!.uid,
      });
      }

     

      log(datatosave.toString());
      usercollection.set(datatosave);

      // Close the loading dialog
      Navigator.of(context).pop();

      // Navigate to home
      Navigator.of(context).pushNamed('/home');
    } catch (e) {
      // Close the loading dialog if an error occurs
      Navigator.of(context).pop();
      // Show error message or handle it as needed
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
        title: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: const Text(
            "Profile photo selection",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 71, 71, 71),
            ),
            textAlign: TextAlign.start,
          ),
        ),
        toolbarHeight: 150,
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  color: Colors.deepPurple, // Set the card color to deep purple
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: Colors.grey.withOpacity(0.5),
                  child: Container(
                    width: 350, // Make the card wider
                    height: 350, // Make the card taller
                    padding: const EdgeInsets.all(
                        30), // Adjust padding inside the card
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
                                    'lib/images/chicken.png', // Path to your default image
                                    fit: BoxFit
                                        .cover, // Ensures the image covers the available space
                                    width:
                                        160, // Adjust width to fit within the circle
                                    height:
                                        160, // Adjust height to fit within the circle
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
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => _showImageSourceDialog(context),
                          child: const Text(
                            'Add Profile Picture',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Spacing between card and button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize:
                        const Size(double.infinity, 50), // Full-width button
                  ),
                  onPressed: () async {
                    await _uploadImage();
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
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
        title: const Text('Select image source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
