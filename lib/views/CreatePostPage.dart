import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreatePostPage extends StatefulWidget {
  final String userId;
  final String goalId;
  final String taskId;

  CreatePostPage({required this.userId, required this.goalId, required this.taskId});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _postContentController = TextEditingController();
  File? _imageFile; // Holds the selected image file
  final ImagePicker _picker = ImagePicker(); // Used for picking images
  bool _isUploading = false; // For showing a progress indicator during upload

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('posts/${widget.userId}/$fileName');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL(); // Get the image URL
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _createPost() async {
    String postContent = _postContentController.text;

    if (postContent.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      // If an image is selected, upload it and get the URL
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      // Store the post data in Firestore
      FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('goals')
          .doc(widget.goalId)
          .collection('tasks')
          .doc(widget.taskId)
          .collection('posts')
          .add({
        'content': postContent,
        'postDate': DateTime.now(),
        'photo': imageUrl ?? '', // Store the image URL if available
      });

      setState(() {
        _isUploading = false;
      });

      Navigator.of(context).pop(); // Return to the previous page after posting
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _postContentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Post about completing the task',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _imageFile != null
                ? Image.file(_imageFile!, height: 150)
                : Text('No image selected'),
            TextButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo),
              label: Text('Pick an Image'),
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createPost,
                    child: Text('Post'),
                  ),
          ],
        ),
      ),
    );
  }
}
