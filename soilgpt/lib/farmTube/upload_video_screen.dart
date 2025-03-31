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
  TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];
  bool _isUploading = false;
  double _uploadProgress = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
      });
    }
  }

  void _addTag() {
    String tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

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

      await _firestore.collection("videos").add({
        "title": _titleController.text,
        "description": _descriptionController.text,
        "videoUrl": videoUrl,
        "username": user.displayName ?? "Anonymous",
        "tags": _tags,
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
        _tags.clear();
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
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        title: Text("Upload Video", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true, // ✅ Prevents overflow
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _video == null
                        ? Text("No video selected", style: TextStyle(fontSize: 16, color: Colors.black54))
                        : Text("Video selected: ${_video!.path.split('/').last}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: Icon(Icons.video_library),
                      label: Text("Pick Video"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildTextField("Video Title", _titleController),
              SizedBox(height: 15),
              _buildTextField("Video Description", _descriptionController),
              SizedBox(height: 15),
              _buildTagsInput(),
              SizedBox(height: 25),
              _isUploading
                  ? LinearProgressIndicator(value: _uploadProgress)
                  : ElevatedButton(
                onPressed: _uploadVideo,
                child: Text("Upload Video"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, minimumSize: Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField("Enter Tags", _tagController),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addTag,
              child: Text("Add"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: _tags.map((tag) => Chip(label: Text(tag), onDeleted: () => _removeTag(tag))).toList(),
        ),
      ],
    );
  }
}
