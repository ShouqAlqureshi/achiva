import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  int _characterCount = 0;
  final int _characterLimit = 280;

  final Color customPurple = Color(0xFF8E24AA);

  @override
  void initState() {
    super.initState();
    _postContentController.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    _postContentController.removeListener(_updateCharacterCount);
    _postContentController.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = _postContentController.text.length;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
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
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _createPost() async {
    String postContent = _postContentController.text;
    print('Creating post with content: $postContent');
    print('UserId: ${widget.userId}, GoalId: ${widget.goalId}, TaskId: ${widget.taskId}');

    if (postContent.isNotEmpty || _imageFile != null) {
      setState(() {
        _isUploading = true;
      });

      String? imageUrl;
      if (_imageFile != null) {
        print('Uploading image...');
        imageUrl = await _uploadImage(_imageFile!);
        print('Image uploaded. URL: $imageUrl');
      }

      print('Attempting to add post to Firestore...');
      try {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.userId)
            .collection('goals')
            .doc(widget.goalId)
            .collection('tasks')
            .doc(widget.taskId)
            .collection('posts')
            .add({
          'content': postContent,
          'postDate': FieldValue.serverTimestamp(),
          'photo': imageUrl ?? '',
        });
        
        print('Post added successfully to Firestore. Document ID: ${docRef.id}');
        
        // Verify the data was written correctly
        DocumentSnapshot verifyDoc = await docRef.get();
        if (verifyDoc.exists) {
          if (kDebugMode) {
            print('Verification: Document exists');
          }
          Map<String, dynamic> data = verifyDoc.data() as Map<String, dynamic>;
          if (kDebugMode) {
            print('Verification data: $data');
          }
        } else {
          if (kDebugMode) {
            print('Verification failed: Document does not exist');
          }
        }

        // Check the number of documents in the posts collection
        QuerySnapshot postsQuery = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.userId)
            .collection('goals')
            .doc(widget.goalId)
            .collection('tasks')
            .doc(widget.taskId)
            .collection('posts')
            .get();
        
        if (kDebugMode) {
          print('Total number of posts in this task: ${postsQuery.docs.length}');
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Delay pop to allow user to see the message
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });

      } catch (e) {
        if (kDebugMode) {
          print('Error adding post to Firestore: $e');
        }
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isUploading = false;
      });
    } else {
      if (kDebugMode) {
        print('Post content is empty and no image selected');
      }
      // Show warning message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add some content or an image to your post.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isNearLimit = _characterCount > _characterLimit - 10 && _characterCount <= _characterLimit;
    bool isOverLimit = _characterCount > _characterLimit;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: customPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: (_characterCount > 0 && _characterCount <= _characterLimit) || _imageFile != null
                ? _createPost
                : null,
            child: Text(
              'Post',
              style: TextStyle(
                color: (_characterCount > 0 && _characterCount <= _characterLimit) || _imageFile != null
                    ? customPurple
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _postContentController,
                maxLines: null,
                maxLength: _characterLimit,
                decoration: InputDecoration(
                  hintText: "How was it!",
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isNearLimit
                      ? '${_characterLimit - _characterCount} characters left'
                      : isOverLimit
                          ? 'Character limit exceeded'
                          : '${_characterCount}/${_characterLimit}',
                  style: TextStyle(
                    color: isOverLimit ? Colors.red : (isNearLimit ? Colors.orange : Colors.grey),
                    fontWeight: isNearLimit || isOverLimit ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
            if (_imageFile != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(_imageFile!, height: 200),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _imageFile = null),
                  ),
                ],
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.photo_library, color: customPurple),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: customPurple),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}