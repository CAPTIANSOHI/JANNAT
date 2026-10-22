import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const TikTokApp());
}

class TikTokApp extends StatelessWidget {
  const TikTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TikTok Clone',
      home: TikTokFeedScreen(),
    );
  }
}

class VideoModel {
  final String id;
  final String videoUrl;
  final String username;
  final String caption;
  final String songTitle;
  int likes;
  int comments;
  bool isLiked;
  bool isFollowed;

  VideoModel({
    required this.id,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.songTitle,
    required this.likes,
    required this.comments,
    this.isLiked = false,
    this.isFollowed = false,
  });
}

class TikTokFeedScreen extends StatefulWidget {
  const TikTokFeedScreen({super.key});

  @override
  State<TikTokFeedScreen> createState() => _TikTokFeedScreenState();
}

class _TikTokFeedScreenState extends State<TikTokFeedScreen> {
  final PageController _pageController = PageController();

  final List<VideoModel> _videos = [
    VideoModel(
      id: '1',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-girl-dancing-happy-in-a-field-of-yellow-flowers-40439-large.mp4',
      username: '@urban_dancer',
      caption: 'Dancing under the sun ✨ #vibes #trending',
      songTitle: 'Original Audio - Urban Beat',
      likes: 12400,
      comments: 320,
    ),
    VideoModel(
      id: '2',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-young-woman-skater-riding-a-skateboard-at-sunset-40348-large.mp4',
      username: '@skater_pro',
      caption: 'Sunset cruise on the deck 🛹🔥',
      songTitle: 'Chill Sunset Beats - LoFi',
      likes: 85200,
      comments: 1140,
    ),
    VideoModel(
      id: '3',
      videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-waves-in-the-water-1164-large.mp4',
      username: '@nature_daily',
      caption: 'Calm ocean tides for peace of mind 🌊',
      songTitle: 'Ocean Waves Sound - Relax',
      likes: 45000,
      comments: 530,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return TikTokVideoItem(
            video: _videos[index],
          );
        },
      ),
    );
  }
}

class TikTokVideoItem extends StatefulWidget {
  final VideoModel video;

  const TikTokVideoItem({
    super.key,
    required this.video,
  });

  @override
  State<TikTokVideoItem> createState() => _TikTokVideoItemState();
}

class _TikTokVideoItemState extends State<TikTokVideoItem>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isHeartAnimating = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    )..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  void _triggerLike() {
    setState(() {
      if (!widget.video.isLiked) {
        widget.video.isLiked = true;
        widget.video.likes++;
      }
      _isHeartAnimating = true;
    });

    _animController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => _isHeartAnimating = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            onDoubleTap: _triggerLike,
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
        ),
        if (_isHeartAnimating)
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(
                Icons.favorite,
                color: Color(0xFFFE2C55),
                size: 110,
              ),
            ),
          ),
        if (_controller.value.isInitialized && !_controller.value.isPlaying)
          const Center(
            child: Icon(
              Icons.play_arrow,
              size: 80,
              color: Colors.white54,
            ),
          ),
        Positioned(
          left: 16,
          bottom: 24,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.video.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.video.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.video.songTitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                    ),
                  ),
                  if (!widget.video.isFollowed)
                    Positioned(
                      bottom: -6,
                      left: 14,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            widget.video.isFollowed = true;
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFE2C55),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.video.isLiked = !widget.video.isLiked;
                    widget.video.isLiked ? widget.video.likes++ : widget.video.likes--;
                  });
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 38,
                      color: widget.video.isLiked
                          ? const Color(0xFFFE2C55)
                          : Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.video.likes}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comments section')),
                  );
                },
                child: Column(
                  children: [
                    const Icon(Icons.comment, size: 36, color: Colors.white),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.video.comments}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link Copied!')),
                  );
                },
                child: const Column(
                  children: [
                    Icon(Icons.reply, size: 36, color: Colors.white),
                    SizedBox(height: 4),
                    Text('Share', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
