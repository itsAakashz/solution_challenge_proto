import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgriCommunityScreen extends StatefulWidget {
  @override
  _AgriCommunityScreenState createState() => _AgriCommunityScreenState();
}

class _AgriCommunityScreenState extends State<AgriCommunityScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _postController = TextEditingController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = userDoc.data()?['isAdmin'] ?? false;
      });
    }
  }

  Future<void> _addPost() async {
    final user = _auth.currentUser;
    if (user != null && _postController.text.isNotEmpty) {
      await _firestore.collection('community_posts').add({
        'content': _postController.text,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Admin',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _postController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AgriCommunity"),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isAdmin
                      ? "You are an admin and can post content"
                      : "You can only view posts from admins"),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      decoration: InputDecoration(
                        hintText: "Share agricultural knowledge...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.green),
                    onPressed: _addPost,
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('community_posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading posts'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    final post = snapshot.data!.docs[index];
                    final data = post.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    data['authorName'] ?? 'Admin',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    _formatTimestamp(data['timestamp']),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(data['content']),
                              if (_isAdmin && data['authorId'] == _auth.currentUser?.uid)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      post.reference.delete();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}