import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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

      final List<Map<String, dynamic>> videoData = querySnapshot.docs.map((doc) {
        return {
          'url': doc['videoUrl'] as String,
          'title': doc['title'] as String,
          'description': doc['description'] as String,
          'username': doc['username'] ?? 'Unknown',
          'videoId': doc.id // Store the video ID to fetch comments
        };
      }).toList();

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

  VideoItem({
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.username,
    required this.videoId,
  });

  @override
  _VideoItemState createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
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
      builder: (context) {
        return CommentSection(videoId: widget.videoId);
      },
    );
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
          Chewie(controller: _chewieController!), // Video is shown here

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent], // Adjusted color here
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
                IconButton(icon: Icon(Icons.favorite_border, color: Colors.white, size: 28), onPressed: () {}),
                SizedBox(height: 12),
                IconButton(icon: Icon(Icons.share, color: Colors.white, size: 28), onPressed: _shareVideo),
                SizedBox(height: 12),
                IconButton(icon: Icon(Icons.comment, color: Colors.white, size: 28), onPressed: () => _showComments(context)),
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
  late CollectionReference _commentsRef;

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
        'replies': [] // Initialize replies as an empty list if they don't exist
      });
      _commentController.clear();
    }
  }

  void _addReply(String commentId) {
    if (_commentController.text.isNotEmpty) {
      _commentsRef.doc(commentId).update({
        'replies': FieldValue.arrayUnion([ // Use arrayUnion to safely add replies
          {'reply': _commentController.text, 'timestamp': FieldValue.serverTimestamp()}
        ])
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 400,
      child: Column(
        children: [
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(comment['comment']),
                          subtitle: Text(comment['timestamp']?.toDate()?.toString() ?? 'Just now'),
                          trailing: IconButton(
                            icon: Icon(Icons.reply),
                            onPressed: () => _showReplyDialog(context, comment.id),
                          ),
                        ),
                        if (comment['replies'] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              children: List.generate(comment['replies'].length, (replyIndex) {
                                var reply = comment['replies'][replyIndex];
                                return ListTile(
                                  title: Text(reply['reply']),
                                  subtitle: Text(reply['timestamp']?.toDate()?.toString() ?? 'Just now'),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(hintText: 'Add a comment...'),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _addComment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reply to Comment'),
          content: TextField(
            controller: _commentController,
            decoration: InputDecoration(hintText: 'Enter your reply...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _addReply(commentId);
                Navigator.pop(context);
              },
              child: Text('Reply'),
            ),
          ],
        );
      },
    );
  }
}
