import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadVideoScreen extends StatefulWidget {
  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? _video;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Picks a video from the gallery
  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
      });
    }
  }

  /// Uploads video to Firebase Storage and stores metadata in Firestore
  Future<void> _uploadVideo() async {
    if (_video == null || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a video and enter title & description")),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ User not logged in!")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.mp4";
      Reference storageRef = _storage.ref().child("videos/$fileName");

      UploadTask uploadTask = storageRef.putFile(_video!);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress = progress;
        });
      });

      TaskSnapshot taskSnapshot = await uploadTask;
      String videoUrl = await taskSnapshot.ref.getDownloadURL();

      // Store video details in Firestore
      await _firestore.collection("videos").add({
        "title": _titleController.text,
        "description": _descriptionController.text,
        "videoUrl": videoUrl,
        "username": user.displayName ?? "Anonymous",
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Video uploaded successfully!")),
      );

      setState(() {
        _isUploading = false;
        _video = null;
        _uploadProgress = 0;
        _titleController.clear();
        _descriptionController.clear();
      });

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Failed to upload video: $error")),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Video")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _video == null
                ? Text("No video selected", style: TextStyle(fontSize: 16))
                : Text("Video selected: ${_video!.path.split('/').last}", style: TextStyle(fontSize: 16)),

            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text("Pick Video"),
            ),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Video Title"),
            ),

            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Video Description"),
            ),

            SizedBox(height: 20),

            _isUploading
                ? Column(
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                SizedBox(height: 10),
                Text("${(_uploadProgress * 100).toStringAsFixed(2)}% uploaded"),
              ],
            )
                : ElevatedButton(
              onPressed: _uploadVideo,
              child: Text("Upload Video"),
            ),
          ],
        ),
      ),
    );
  }
}
