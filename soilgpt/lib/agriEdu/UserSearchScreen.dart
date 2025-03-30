import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatscreen.dart';

class IdeaSharingScreen extends StatefulWidget {
  @override
  _IdeaSharingScreenState createState() => _IdeaSharingScreenState();
}

class _IdeaSharingScreenState extends State<IdeaSharingScreen> {
  final TextEditingController _ideaController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('idea_images/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _shareIdea() async {
    String ideaText = _ideaController.text.trim();
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    if (ideaText.isNotEmpty || imageUrl != null) {
      await FirebaseFirestore.instance.collection('ideas').add({
        'userId': currentUserId,
        'text': ideaText,
        'imageUrl': imageUrl,
        'likes': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _ideaController.clear();
      setState(() {
        _selectedImage = null;
      });
    }
  }

  void _likeIdea(String ideaId, int currentLikes) {
    FirebaseFirestore.instance.collection('ideas').doc(ideaId).update({
      'likes': currentLikes + 1,
    });
  }

  Widget _buildIdeaItem(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
      builder: (context, snapshot) {
        String username = "User";
        String? profilePic;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          username = userData['name'] ?? "User";
          profilePic = userData['profilePic'];
        }

        return Card(
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (data['userId'] != currentUserId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: data['userId'],
                            receiverName: username,
                          ),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                        backgroundColor: Colors.green,
                        child: profilePic == null ? Icon(Icons.person, color: Colors.white) : null,
                      ),
                      SizedBox(width: 10),
                      Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(data['text'] ?? '', style: TextStyle(fontSize: 16)),
                if (data['imageUrl'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.network(data['imageUrl'], height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up, color: Colors.green),
                      onPressed: () => _likeIdea(doc.id, data['likes'] ?? 0),
                    ),
                    Text("${data['likes'] ?? 0} Likes"),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AgriEdu Idea Sharing")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('ideas').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                return ListView(
                  children: snapshot.data!.docs.map((doc) => _buildIdeaItem(doc)).toList(),
                );
              },
            ),
          ),
          _buildIdeaInput(),
        ],
      ),
    );
  }

  Widget _buildIdeaInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.image, color: Colors.green), onPressed: _pickImage),
          Expanded(
            child: TextField(controller: _ideaController, decoration: InputDecoration(hintText: "Share your idea...")),
          ),
          IconButton(icon: Icon(Icons.send, color: Colors.green), onPressed: _shareIdea),
        ],
      ),
    );
  }
}
