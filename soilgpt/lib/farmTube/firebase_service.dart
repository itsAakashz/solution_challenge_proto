import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pick a video from gallery
  Future<File?> pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) return File(pickedFile.path);
    return null;
  }

  // Upload video to Firebase Storage
  Future<String?> uploadVideo(File video) async {
    try {
      String fileName = "videos/${DateTime.now().millisecondsSinceEpoch}.mp4";
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(video);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL(); // Get download URL
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // Save video metadata to Firestore
  Future<void> saveVideoData(String videoUrl, String title) async {
    await _firestore.collection('videos').add({
      'title': title,
      'videoUrl': videoUrl,
      'likes': 0,
      'comments': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Fetch videos from Firestore
  Stream<QuerySnapshot> getVideos() {
    return _firestore.collection('videos').orderBy('createdAt', descending: true).snapshots();
  }

  // Like video
  Future<void> likeVideo(String videoId) async {
    DocumentReference videoRef = _firestore.collection('videos').doc(videoId);
    videoRef.update({'likes': FieldValue.increment(1)});
  }

  // Add comment
  Future<void> addComment(String videoId, String comment) async {
    DocumentReference videoRef = _firestore.collection('videos').doc(videoId);
    videoRef.update({'comments': FieldValue.arrayUnion([comment])});
  }
}
