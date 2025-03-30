import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UploadVideoScreen extends StatefulWidget {
  @override
  _UploadVideoScreenState createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  File? _video;
  bool _isUploading = false;
  double _uploadProgress = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickVideo() async {
    final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_video == null || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a video and enter title & description")));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      String sanitizedTitle = _titleController.text.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      String fileName = 'videos/$sanitizedTitle.mp4';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = storageRef.putFile(_video!);

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        setState(() {
          _uploadProgress = progress;
        });
      });

      await uploadTask;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Video uploaded successfully!")));
    } catch (e) {
      print('❌ Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to upload video")));
    } finally {
      setState(() {
        _isUploading = false;
        _video = null;
        _uploadProgress = 0;
        _titleController.clear();
        _descriptionController.clear();
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            _video != null
                ? Text("✅ Video Selected")
                : ElevatedButton(
              onPressed: _pickVideo,
              child: Text("Pick Video"),
            ),
            SizedBox(height: 20),
            _isUploading
                ? Column(
              children: [
                CircularProgressIndicator(value: _uploadProgress / 100),
                SizedBox(height: 10),
                Text("${_uploadProgress.toStringAsFixed(0)}% Uploaded"),
              ],
            )
                : _video != null
                ? ElevatedButton(
              onPressed: _uploadVideo,
              child: Text("Upload Video"),
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
