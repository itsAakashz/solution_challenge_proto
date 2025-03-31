import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upload_video_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Short Video Feed',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.green.shade900,
        fontFamily: 'Poppins',
      ),
      home: ShortVideoFeed(),
    );
  }
}

class ShortVideoFeed extends StatefulWidget {
  @override
  _ShortVideoFeedState createState() => _ShortVideoFeedState();
}

class _ShortVideoFeedState extends State<ShortVideoFeed> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initVideos();
  }

  Future<void> _initVideos() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> videoData = await Future.wait(
        querySnapshot.docs.map((doc) async {
          bool isLiked = false;
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final likeDoc = await FirebaseFirestore.instance
                .collection('videos')
                .doc(doc.id)
                .collection('likes')
                .doc(currentUser.uid)
                .get();
            isLiked = likeDoc.exists;
          }

          final likesSnapshot = await FirebaseFirestore.instance
              .collection('videos')
              .doc(doc.id)
              .collection('likes')
              .get();

          return {
            'url': doc['videoUrl'] as String,
            'title': doc['title'] as String,
            'description': doc['description'] as String,
            'username': doc['username'] ?? 'Unknown',
            'videoId': doc.id,
            'isLiked': isLiked,
            'likeCount': likesSnapshot.size,
          };
        }),
      );

      setState(() {
        videos = videoData;
      });
    } catch (e) {
      print('Error fetching videos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Short Video Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadVideoScreen()),
              ).then((_) => _initVideos());
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : videos.isEmpty
          ? Center(child: Text('No videos available', style: TextStyle(color: Colors.white70)))
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return VideoItem(
            videoUrl: videos[index]['url']!,
            title: videos[index]['title']!,
            description: videos[index]['description']!,
            username: videos[index]['username']!,
            videoId: videos[index]['videoId']!,
            isLiked: videos[index]['isLiked'] ?? false,
            likeCount: videos[index]['likeCount'] ?? 0,
            onLikeChanged: (bool isLiked, int newCount) {
              setState(() {
                videos[index]['isLiked'] = isLiked;
                videos[index]['likeCount'] = newCount;
              });
            },
          );
        },
      ),
    );
  }
}

class VideoItem extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final String username;
  final String videoId;
  final bool isLiked;
  final int likeCount;
  final Function(bool, int) onLikeChanged;

  VideoItem({
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.username,
    required this.videoId,
    required this.isLiked,
    required this.likeCount,
    required this.onLikeChanged,
  });

  @override
  _VideoItemState createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likeCount = widget.likeCount;
    _initializeVideo();
  }

  void _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: true,
      showControls: false,
      aspectRatio: 9 / 16,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _shareVideo() {
    Share.share(widget.videoUrl);
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CommentSection(videoId: widget.videoId);
      },
    );
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to like videos')),
      );
      return;
    }

    final likeRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.videoId)
        .collection('likes')
        .doc(currentUser.uid);

    if (_isLiked) {
      await likeRef.delete();
      setState(() {
        _isLiked = false;
        _likeCount--;
      });
    } else {
      await likeRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
      setState(() {
        _isLiked = true;
        _likeCount++;
      });
    }

    widget.onLikeChanged(_isLiked, _likeCount);
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || !_videoController.value.isInitialized) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return GestureDetector(
      onTap: () {
        if (_videoController.value.isPlaying) {
          _videoController.pause();
        } else {
          _videoController.play();
        }
      },
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${widget.username}', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(widget.title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(widget.description, style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text(
                      _likeCount.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white, size: 28),
                  onPressed: _shareVideo,
                ),
                SizedBox(height: 12),
                IconButton(
                  icon: Icon(Icons.comment, color: Colors.white, size: 28),
                  onPressed: () => _showComments(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentSection extends StatefulWidget {
  final String videoId;

  CommentSection({required this.videoId});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  late CollectionReference _commentsRef;
  String? _replyingToCommentId;
  String? _replyingToUsername;
  Map<String, bool> _showReplies = {};

  @override
  void initState() {
    super.initState();
    _commentsRef = FirebaseFirestore.instance.collection('videos').doc(widget.videoId).collection('comments');
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      _commentsRef.add({
        'comment': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'username': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'replies': []
      });
      _commentController.clear();
    }
  }

  void _addReply(String commentId) {
    if (_replyController.text.isNotEmpty) {
      _commentsRef.doc(commentId).update({
        'replies': FieldValue.arrayUnion([
          {
            'reply': _replyController.text,
            'timestamp': FieldValue.serverTimestamp(),
            'username': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
            'userId': FirebaseAuth.instance.currentUser?.uid,
          }
        ])
      });
      _replyController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUsername = null;
      });
    }
  }

  void _toggleRepliesVisibility(String commentId) {
    setState(() {
      _showReplies[commentId] = !(_showReplies[commentId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Text(
            'Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _commentsRef.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No comments yet.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var comment = snapshot.data!.docs[index];
                    bool showReplies = _showReplies[comment.id] ?? false;
                    bool hasReplies = comment['replies'] != null && comment['replies'].isNotEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(comment['username'] ?? 'Anonymous',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(comment['comment']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.reply),
                                onPressed: () {
                                  setState(() {
                                    _replyingToCommentId = comment.id;
                                    _replyingToUsername = comment['username'];
                                  });
                                },
                              ),
                              if (hasReplies)
                                IconButton(
                                  icon: Icon(showReplies ? Icons.expand_less : Icons.expand_more),
                                  onPressed: () => _toggleRepliesVisibility(comment.id),
                                ),
                            ],
                          ),
                        ),

                        // Show reply input if this is the comment being replied to
                        if (_replyingToCommentId == comment.id)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _replyController,
                                    decoration: InputDecoration(
                                      hintText: 'Replying to ${_replyingToUsername}...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () => _addReply(comment.id),
                                ),
                              ],
                            ),
                          ),

                        // Show replies if expanded
                        if (showReplies && hasReplies)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              children: List.generate(comment['replies'].length, (replyIndex) {
                                var reply = comment['replies'][replyIndex];
                                return ListTile(
                                  leading: Icon(Icons.subdirectory_arrow_right, size: 20),
                                  title: Text(reply['username'] ?? 'Anonymous',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(reply['reply']),
                                );
                              }),
                            ),
                          )
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Main comment input
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}