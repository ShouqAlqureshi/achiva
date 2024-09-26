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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Colors.deepPurple, // Set the card color to deep purple
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: Colors.grey.withOpacity(0.5),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85, // Make the card wider
                height: MediaQuery.of(context).size.height * 0.6, // Make the card taller
                padding: const EdgeInsets.all(30), // Adjust padding inside the card
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _imageFile == null
                        ? CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            ),
                          )
                        : CircleAvatar(
                            radius: 80,
                            backgroundImage: FileImage(File(_imageFile!.path)),
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          isFormSubmitted = true;
                        });
                        if (_imageFile != null) {
                          final usercollection = FirebaseFirestore.instance
                              .collection("Users")
                              .doc(FirebaseAuth.instance.currentUser!.uid);
                          final datatosave = ModalRoute.of(context)!
                              .settings
                              .arguments as Map<String, dynamic>;
                          await FirebaseStorage.instance
                              .ref()
                              .child(
                                  "Users/${Uri.file(_imageFile!.path).pathSegments.last}")
                              .putFile(File(_imageFile!.path))
                              .then((val) async {
                            val.ref
                                .getDownloadURL()
                                .then((urlOfImageUploaded) async {
                              debugPrint(urlOfImageUploaded);
                              datatosave.addAll({
                                "photo": urlOfImageUploaded,
                                'id': FirebaseAuth.instance.currentUser!.uid
                              });
                              log(datatosave.toString());
                              usercollection.set(datatosave);
                            });
                          });

                          Navigator.of(context).pushNamed('/home');
                        }
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                    if (isFormSubmitted && _imageFile == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          "Photo is required",
                          style: TextStyle(
                            color: Color.fromARGB(255, 195, 24, 12),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
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
}
