import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init: $e");
  }
  runApp(const TikTokApp());
}

class TikTokApp extends StatelessWidget {
  const TikTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jannat Shorts',
      theme: ThemeData.dark(),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // 1. Camera Recording & Upload System
  Future<void> _recordAndUploadVideo() async {
    final XFile? recordedVideo = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );

    if (recordedVideo == null) return;

    setState(() => _isUploading = true);

    try {
      File file = File(recordedVideo.path);
      String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Firebase Storage vich upload
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore Database vich entry
      await FirebaseFirestore.instance.collection('videos').add({
        'videoUrl': downloadUrl,
        'username': '@captiansohi',
        'caption': 'Fresh recorded video! 🔥 #jannat',
        'songTitle': 'Original Audio - Sound',
        'likes': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video live ho gayi!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Firestore ton Live Real-Time Feed
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('videos')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              // Fallback default videos agar cloud khali hove
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return PageView(
                  scrollDirection: Axis.vertical,
                  children: const [
                    TikTokVideoItem(
                      docId: 'demo1',
                      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-girl-dancing-happy-in-a-field-of-yellow-flowers-40439-large.mp4',
                      username: '@dancer_star',
                      caption: 'Record icon daba ke apni video pao! ✨',
                      songTitle: 'Trending Beats',
                      likes: 120,
                    ),
                  ],
                );
              }

              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return TikTokVideoItem(
                    docId: docs[index].id,
                    videoUrl: data['videoUrl'] ?? '',
                    username: data['username'] ?? '@user',
                    caption: data['caption'] ?? '',
                    songTitle: data['songTitle'] ?? 'Original Sound',
                    likes: data['likes'] ?? 0,
                  );
                },
              );
            },
          ),

          // Uploading Status Indicator
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFE2C55)),
                    SizedBox(height: 12),
                    Text('Video cloud te upload ho rahi hai...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),

          // Bottom Bar Record (+ Camera) Button
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _recordAndUploadVideo,
                  child: Container(
                    height: 48,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFE2C55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.videocam, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TikTokVideoItem extends StatefulWidget {
  final String docId;
  final String videoUrl;
  final String username;
  final String caption;
  final String songTitle;
  final int likes;

  const TikTokVideoItem({
    super.key,
    required this.docId,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.songTitle,
    required this.likes,
  });

  @override
  State<TikTokVideoItem> createState() => _TikTokVideoItemState();
}

class _TikTokVideoItemState extends State<TikTokVideoItem> {
  late VideoPlayerController _controller;
  bool _isLiked = false;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 2. Real-Time Bottom Comment Sheet
  void _openCommentsDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final commentCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(color: Colors.white24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('videos')
                        .doc(widget.docId)
                        .collection('comments')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('Haje koi comment nahi. Pehla comment tusi karo!'));
                      }
                      final cDocs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: cDocs.length,
                        itemBuilder: (context, i) {
                          final c = cDocs[i].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, size: 18, color: Colors.white),
                            ),
                            title: Text(c['user'] ?? 'Anonymous', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(c['text'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          decoration: InputDecoration(
                            hintText: 'Add comment...',
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFFE2C55)),
                        onPressed: () {
                          if (commentCtrl.text.trim().isNotEmpty) {
                            FirebaseFirestore.instance
                                .collection('videos')
                                .doc(widget.docId)
                                .collection('comments')
                                .add({
                              'user': '@guest',
                              'text': commentCtrl.text.trim(),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            commentCtrl.clear();
                          }
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        ),

        // Bottom Details
        Positioned(
          left: 16,
          bottom: 74,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.music_note, size: 16),
                  const SizedBox(width: 4),
                  Text(widget.songTitle, style: const TextStyle(fontSize: 13)),
                ],
              )
            ],
          ),
        ),

        // Action Buttons
        Positioned(
          right: 12,
          bottom: 74,
          child: Column(
            children: [
              IconButton(
                icon: Icon(Icons.favorite, size: 36, color: _isLiked ? const Color(0xFFFE2C55) : Colors.white),
                onPressed: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    _isLiked ? _likeCount++ : _likeCount--;
                  });
                  // Cloud DB Like Counter Update
                  FirebaseFirestore.instance.collection('videos').doc(widget.docId).update({
                    'likes': _likeCount,
                  }).catchError((_) {});
                },
              ),
              Text('$_likeCount', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 14),
              IconButton(
                icon: const Icon(Icons.comment, size: 34, color: Colors.white),
                onPressed: _openCommentsDrawer,
              ),
              const Text('Comments', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
