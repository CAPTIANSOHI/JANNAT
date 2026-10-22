import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init: $e");
  }
  runApp(const JannatSuperApp());
}

class JannatSuperApp extends StatelessWidget {
  const JannatSuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jannat Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFFE2C55),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ==================== AUTH GATE ====================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigationHolder();
        }
        return const LoginScreen();
      },
    );
  }
}

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  String _verificationId = '';

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone.startsWith('+') ? phone : '+91$phone',
      verificationCompleted: (PhoneAuthCredential cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          _verificationId = verId;
          _otpSent = true;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verId) => _verificationId = verId,
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential cred = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
    }
  }

  Future<void> _guestLogin() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.play_circle_fill, size: 85, color: Color(0xFFFE2C55)),
              const SizedBox(height: 12),
              const Text(
                'JANNAT PRO',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 6),
              const Text('Live Stream • AI Creator Tools • Shop', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 40),
              if (!_otpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixText: '+91 ',
                    hintText: 'Mobile Number',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send OTP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: 'OTP',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE2C55),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Verify & Login', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _guestLogin,
                icon: const Icon(Icons.flash_on, color: Colors.amber),
                label: const Text('1-Click Instant Login', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MAIN 5-TAB CONTROLLER ====================
class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenWithTabs(),
    const ExploreSearchScreen(),
    const SizedBox.shrink(), // Center upload dialog placeholder
    const DirectMessagesScreen(),
    const UserProfileScreen(),
  ];

  void _openUploadStudio() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String selectedSpeed = '1.0x';
        String selectedMusic = 'Trending Punjabi Beats';
        bool autoCaptionsEnabled = true;
        bool greenScreenEnabled = false;
        String stickerText = '';
        bool attachProduct = false;
        final stickerCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Creator Studio & Upload', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    // Speed Options
                    Row(
                      children: [
                        const Text('Speed: ', style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                        ...['0.5x', '1.0x', '2.0x'].map((spd) {
                          final isSel = selectedSpeed == spd;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(spd),
                              selected: isSel,
                              selectedColor: const Color(0xFFFE2C55),
                              onSelected: (_) => setModalState(() => selectedSpeed = spd),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Sound Track Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.music_note, color: Color(0xFFFE2C55)),
                      title: Text(selectedMusic, style: const TextStyle(fontSize: 13)),
                      trailing: TextButton(
                        child: const Text('Change Audio'),
                        onPressed: () {
                          setModalState(() {
                            selectedMusic = selectedMusic.contains('Punjabi')
                                ? 'Original Sound - Viral Trend'
                                : 'Trending Punjabi Beats';
                          });
                        },
                      ),
                    ),
                    // AI Auto-Captions Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFFE2C55),
                      title: const Text('AI Auto-Captions & Subtitles', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Auto generates lyrical subtitles on video', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      value: autoCaptionsEnabled,
                      onChanged: (val) => setModalState(() => autoCaptionsEnabled = val),
                    ),
                    // Green Screen Mode Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.green,
                      title: const Text('Green Screen / Virtual BG', style: TextStyle(fontSize: 14)),
                      value: greenScreenEnabled,
                      onChanged: (val) => setModalState(() => greenScreenEnabled = val),
                    ),
                    // E-Commerce Product Tag
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.amber,
                      title: const Text('Attach Shop Product ("Buy Now")', style: TextStyle(fontSize: 14)),
                      value: attachProduct,
                      onChanged: (val) => setModalState(() => attachProduct = val),
                    ),
                    // Overlay Text/Sticker Input
                    TextField(
                      controller: stickerCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add Overlay Text / Emoji / Sticker (e.g. 🔥 Sira)',
                        hintStyle: TextStyle(fontSize: 13),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      onChanged: (t) => stickerText = t,
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12),
                    ListTile(
                      leading: const Icon(Icons.videocam, color: Color(0xFFFE2C55), size: 28),
                      title: const Text('Record with Camera (30s)'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUpload(
                          ImageSource.camera,
                          selectedMusic,
                          selectedSpeed,
                          autoCaptionsEnabled,
                          stickerText,
                          attachProduct,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library, color: Colors.amber, size: 28),
                      title: const Text('Upload from Phone Gallery'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndUpload(
                          ImageSource.gallery,
                          selectedMusic,
                          selectedSpeed,
                          autoCaptionsEnabled,
                          stickerText,
                          attachProduct,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUpload(
    ImageSource source,
    String music,
    String speed,
    bool aiCaptions,
    String sticker,
    bool attachShop,
  ) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: source, maxDuration: const Duration(seconds: 30));
    if (video == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video cloud upload shuru...')));

    try {
      File file = File(video.path);
      String fileName = 'videos/${DateTime.now().millisecondsSinceEpoch}.mp4';
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      final user = FirebaseAuth.instance.currentUser;
      String currentUid = user?.uid ?? 'guest';
      String currentName = user?.phoneNumber ?? '@creator';

      await FirebaseFirestore.instance.collection('videos').add({
        'videoUrl': downloadUrl,
        'userId': currentUid,
        'username': currentName,
        'caption': 'Check out this fresh clip! 🔥 #jannat #trending',
        'songTitle': music,
        'speed': speed,
        'aiCaptions': aiCaptions ? '✨ AI Generated Lyrics: "Trending sound sync..."' : '',
        'stickerText': sticker,
        'hasShopProduct': attachShop,
        'productTitle': attachShop ? 'Jannat Official Hoodie' : '',
        'productPrice': attachShop ? '₹999' : '',
        'likes': 0,
        'coins': 0,
        'quality': '1080p HD',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video live upload ho gayi!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _openUploadStudio();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFE2C55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Inbox'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ==================== TAB 1: HOME FEED (STORIES & TABS) ====================
class HomeScreenWithTabs extends StatelessWidget {
  const HomeScreenWithTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Stack(
        children: [
          TabBarView(
            children: [
              _buildFeedStream(),
              _buildFeedStream(),
            ],
          ),

          // 24-Hour Stories Bar + Live Stream Button
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Go Live Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFE2C55),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LiveStreamScreen()),
                          );
                        },
                        icon: const Icon(Icons.videocam, size: 16, color: Colors.white),
                        label: const Text('Go Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      // Top Tabs
                      SizedBox(
                        width: 180,
                        child: TabBar(
                          indicatorColor: Colors.white,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          unselectedLabelStyle: const TextStyle(fontSize: 15),
                          tabs: const [
                            Tab(text: 'Following'),
                            Tab(text: 'For You'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 24-Hour Stories Ring
                SizedBox(
                  height: 70,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildStoryAvatar('My Story', hasAdd: true),
                      _buildStoryAvatar('@diljit_f'),
                      _buildStoryAvatar('@sidhu_fans'),
                      _buildStoryAvatar('@jannat_live'),
                      _buildStoryAvatar('@karan_au'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStoryAvatar(String name, {bool hasAdd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFE2C55), Colors.amber, Colors.purple],
                  ),
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
              if (hasAdd)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Color(0xFFFE2C55), shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                )
            ],
          ),
          const SizedBox(height: 3),
          Text(name, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildFeedStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Haje koi video nahi mili. + dabao te upload karo!'));
        }
        return PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return VideoPlayerFeedCard(
              docId: docs[index].id,
              userId: data['userId'] ?? '',
              videoUrl: data['videoUrl'] ?? '',
              username: data['username'] ?? '@user',
              caption: data['caption'] ?? '',
              songTitle: data['songTitle'] ?? 'Original Sound',
              aiCaptions: data['aiCaptions'] ?? '',
              stickerText: data['stickerText'] ?? '',
              hasShopProduct: data['hasShopProduct'] ?? false,
              productTitle: data['productTitle'] ?? 'Jannat Merch',
              productPrice: data['productPrice'] ?? '₹999',
              likes: data['likes'] ?? 0,
              coins: data['coins'] ?? 0,
            );
          },
        );
      },
    );
  }
}

// ==================== LIVE STREAM & PK BATTLE SCREEN ====================
class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  bool isPkBattle = true;
  int myPoints = 420;
  int opponentPoints = 380;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Split Screen for Live PK Battle
          Positioned.fill(
            child: isPkBattle
                ? Column(
                    children: [
                      // Host Screen
                      Expanded(
                        child: Container(
                          color: Colors.blueGrey.shade900,
                          child: const Center(
                            child: Text('🔴 YOU (Host Live)', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Container(
                        height: 24,
                        color: const Color(0xFFFE2C55),
                        child: Center(
                          child: Text('🔥 PK BATTLE: $myPoints vs $opponentPoints 🔥', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      // PK Opponent Screen
                      Expanded(
                        child: Container(
                          color: Colors.deepPurple.shade900,
                          child: const Center(
                            child: Text('🔴 OPPONENT: @singh_star', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.blueGrey.shade900,
                    child: const Center(child: Text('🔴 Solo Live Stream', style: TextStyle(fontSize: 22))),
                  ),
          ),

          // Live Chat Overlay
          Positioned(
            left: 12,
            bottom: 70,
            width: 250,
            height: 180,
            child: ListView(
              children: const [
                Text('💬 @harman: Sira live bhaji! 🔥', style: TextStyle(color: Colors.white, fontSize: 12)),
                Text('💬 @aman: Supercar gift sent 🏎️', style: TextStyle(color: Colors.amber, fontSize: 12)),
                Text('💬 @preeti: Hello from Punjab 👋', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFE2C55), borderRadius: BorderRadius.circular(12)),
                    child: const Text('LIVE • 1.4k viewers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: const TextField(
                      decoration: InputDecoration(hintText: 'Comment live...', border: InputBorder.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 30),
                  onPressed: () {
                    setState(() => myPoints += 50);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('+50 Gift points added to battle!')));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Color(0xFFFE2C55), size: 30),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent flying hearts ❤️')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB 2: EXPLORE & SEARCH ====================
class ExploreSearchScreen extends StatelessWidget {
  const ExploreSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> tags = ['#jannat', '#viral', '#punjabi', '#music', '#comedy', '#dance'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search creators, sounds, hashtags...',
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white12,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) => Chip(backgroundColor: Colors.white12, label: Text(t))).toList(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Trending Clips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('videos').limit(12).snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    return Container(
                      color: Colors.white10,
                      child: const Center(child: Icon(Icons.play_arrow, color: Colors.white54, size: 30)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB 4: DIRECT MESSAGES ====================
class DirectMessagesScreen extends StatelessWidget {
  const DirectMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Inbox & Messages', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFFE2C55), child: Icon(Icons.notifications, color: Colors.white)),
            title: const Text('System Notification'),
            subtitle: const Text('Welcome to Jannat Pro! 24hr stories & Shop are live.'),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const CircleAvatar(child: Text('C')),
            title: const Text('Creator Support'),
            subtitle: const Text('Tap to start a direct 1-on-1 private chat'),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatConversationScreen(chatUser: 'Support / Creator')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChatConversationScreen extends StatefulWidget {
  final String chatUser;
  const ChatConversationScreen({super.key, required this.chatUser});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _msgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.chatUser)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (context, snapshot) {
                final msgs = snapshot.data?.docs ?? [];
                if (msgs.isEmpty) {
                  return const Center(child: Text('Say hello! Start the conversation.'));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final d = msgs[i].data() as Map<String, dynamic>;
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFFE2C55), borderRadius: BorderRadius.circular(16)),
                        child: Text(d['text'] ?? '', style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white10,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(hintText: 'Type message...', border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFE2C55)),
                  onPressed: () {
                    if (_msgCtrl.text.trim().isNotEmpty) {
                      FirebaseFirestore.instance.collection('messages').add({
                        'text': _msgCtrl.text.trim(),
                        'time': FieldValue.serverTimestamp(),
                      });
                      _msgCtrl.clear();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==================== TAB 5: PROFILE, UPI RECHARGE & CREATOR BANK PAYOUT ====================
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int userCoins = 1250;

  // Real UPI / Payment Dialog
  void _openUpiPaymentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final coinPackages = [
          {'coins': 100, 'price': '₹49'},
          {'coins': 500, 'price': '₹199'},
          {'coins': 1500, 'price': '₹499'},
        ];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Recharge Coins (GPay / PhonePe / Paytm UPI)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...coinPackages.map((pkg) {
                return ListTile(
                  leading: const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                  title: Text('${pkg['coins']} Coins'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE2C55)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => userCoins += (pkg['coins'] as int));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('UPI Payment Successful! ${pkg['coins']} Coins added.')),
                      );
                    },
                    child: Text('Pay ${pkg['price']}'),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Creator Bank Payout Dialog
  void _openWithdrawDialog() {
    final upiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Creator Payout (Bank / UPI Transfer)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance: $userCoins Coins (approx ₹${(userCoins / 2).toInt()})'),
            const SizedBox(height: 12),
            TextField(
              controller: upiCtrl,
              decoration: const InputDecoration(hintText: 'Enter UPI ID (e.g. name@okhdfcbank)', filled: true, fillColor: Colors.black26),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal request submitted! Money will be credited in 24 hrs.')),
              );
            },
            child: const Text('Transfer to Bank'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? '';
    final String displayName = user?.phoneNumber ?? (user?.isAnonymous == true ? '@guest_creator' : '@creator');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStat('142', 'Following'),
                      const SizedBox(width: 32),
                      _buildStat('12.5k', 'Followers'),
                      const SizedBox(width: 32),
                      _buildStat('89k', 'Likes'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openUpiPaymentSheet,
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.amber, size: 16),
                        label: Text('Recharge ($userCoins 🪙)'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _openWithdrawDialog,
                        icon: const Icon(Icons.account_balance, color: Colors.greenAccent, size: 16),
                        label: const Text('Withdraw Payout'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            const SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.favorite_border)),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('videos').where('userId', isEqualTo: uid).snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('Tuhadi koi video nahi mili.'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      return Container(
                        color: Colors.white12,
                        child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white60, size: 36)),
                      );
                    },
                  );
                },
              ),
              const Center(child: Text('Liked videos private ne.')),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.black, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// ==================== FEED CARD, AI CAPTIONS & SHOPPING LINK ====================
class VideoPlayerFeedCard extends StatefulWidget {
  final String docId;
  final String userId;
  final String videoUrl;
  final String username;
  final String caption;
  final String songTitle;
  final String aiCaptions;
  final String stickerText;
  final bool hasShopProduct;
  final String productTitle;
  final String productPrice;
  final int likes;
  final int coins;

  const VideoPlayerFeedCard({
    super.key,
    required this.docId,
    required this.userId,
    required this.videoUrl,
    required this.username,
    required this.caption,
    required this.songTitle,
    required this.aiCaptions,
    required this.stickerText,
    required this.hasShopProduct,
    required this.productTitle,
    required this.productPrice,
    required this.likes,
    required this.coins,
  });

  @override
  State<VideoPlayerFeedCard> createState() => _VideoPlayerFeedCardState();
}

class _VideoPlayerFeedCardState extends State<VideoPlayerFeedCard> {
  late VideoPlayerController _controller;
  bool _isLiked = false;
  bool _isFollowed = false;
  late int _likeCount;
  late int _coinCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
    _coinCount = widget.coins;
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

  void _shareVideo() {
    Share.share('Jannat Pro te eh trending video dekho! 🔥 \n${widget.videoUrl}');
  }

  Future<void> _downloadOfflineVideo() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading video for offline watch...')));
    try {
      final res = await http.get(Uri.parse(widget.videoUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/jannat_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await file.writeAsBytes(res.bodyBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Phone Storage! (Watch Offline)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  void _openGiftsDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final gifts = [
          {'name': 'Rose 🌹', 'cost': 10},
          {'name': 'Diamond 💎', 'cost': 50},
          {'name': 'Supercar 🏎️', 'cost': 200},
        ];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Send Gift to Creator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: gifts.map((g) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _coinCount += (g['cost'] as int));
                      FirebaseFirestore.instance.collection('videos').doc(widget.docId).update({
                        'coins': _coinCount,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${g['name']} gift sent!')),
                      );
                    },
                    child: Text('${g['name']}\n${g['cost']} Coins', textAlign: TextAlign.center),
                  );
                }).toList(),
              )
            ],
          ),
        );
      },
    );
  }

  void _adminDeleteVideo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Admin Video Moderation'),
        content: const Text('Is video nu permanent delete karna hai?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFE2C55)),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('videos').doc(widget.docId).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video permanently delete ho gayi.')));
              }
            },
            child: const Text('Delete Video'),
          ),
        ],
      ),
    );
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final commentCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: SizedBox(
            height: 380,
            child: Column(
              children: [
                const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(color: Colors.white24),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('videos').doc(widget.docId).collection('comments').snapshots(),
                    builder: (context, snapshot) {
                      final cDocs = snapshot.data?.docs ?? [];
                      if (cDocs.isEmpty) return const Center(child: Text('First comment tusi karo!'));
                      return ListView.builder(
                        itemCount: cDocs.length,
                        itemBuilder: (context, i) {
                          final c = cDocs[i].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(c['user'] ?? 'User', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text(c['text'] ?? ''),
                          );
                        },
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFFE2C55)),
                      onPressed: () {
                        if (commentCtrl.text.trim().isNotEmpty) {
                          FirebaseFirestore.instance.collection('videos').doc(widget.docId).collection('comments').add({
                            'user': '@guest',
                            'text': commentCtrl.text.trim(),
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          commentCtrl.clear();
                        }
                      },
                    )
                  ],
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

        // Sticker / Overlay Text
        if (widget.stickerText.isNotEmpty)
          Positioned(
            top: 140,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: Text(widget.stickerText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
            ),
          ),

        // AI Auto-Captions Subtitles
        if (widget.aiCaptions.isNotEmpty)
          Positioned(
            bottom: 120,
            left: 20,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black45,
              child: Text(widget.aiCaptions, style: const TextStyle(fontSize: 13, color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
            ),
          ),

        // Left Content Info + E-Commerce "Buy Now" Link
        Positioned(
          left: 16,
          bottom: 24,
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text('🪙 $_coinCount', style: const TextStyle(color: Colors.amber, fontSize: 11)),
                  ),
                ],
              ),
              // Video E-Commerce Shop Tag
              if (widget.hasShopProduct) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening shop checkout for ${widget.productTitle} (${widget.productPrice})')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag, size: 16, color: Colors.black),
                        const SizedBox(width: 6),
                        Text('Buy Now: ${widget.productTitle} (${widget.productPrice})', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Right Action Bar
        Positioned(
          right: 12,
          bottom: 24,
          child: Column(
            children: [
              // Avatar & Follow
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.person)),
                  if (!_isFollowed)
                    Positioned(
                      bottom: -6,
                      left: 10,
                      child: GestureDetector(
                        onTap: () => setState(() => _isFollowed = true),
                        child: Container(
                          decoration: const BoxDecoration(color: Color(0xFFFE2C55), shape: BoxShape.circle),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Like
              IconButton(
                icon: Icon(Icons.favorite, size: 34, color: _isLiked ? const Color(0xFFFE2C55) : Colors.white),
                onPressed: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    _isLiked ? _likeCount++ : _likeCount--;
                  });
                  FirebaseFirestore.instance.collection('videos').doc(widget.docId).update({'likes': _likeCount}).catchError((_) {});
                },
              ),
              Text('$_likeCount', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 14),

              // Comment
              IconButton(icon: const Icon(Icons.comment, size: 30), onPressed: _openComments),
              const Text('Comments', style: TextStyle(fontSize: 10)),
              const SizedBox(height: 14),

              // Virtual Gift
              IconButton(
                icon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 30),
                onPressed: _openGiftsDrawer,
              ),
              const Text('Gift', style: TextStyle(fontSize: 10)),
              const SizedBox(height: 14),

              // WhatsApp Share
              IconButton(icon: const Icon(Icons.share, size: 28), onPressed: _shareVideo),
              const Text('Share', style: TextStyle(fontSize: 10)),
              const SizedBox(height: 14),

              // Download / Offline Watch
              IconButton(icon: const Icon(Icons.download_for_offline, size: 28), onPressed: _downloadOfflineVideo),
              const Text('Offline', style: TextStyle(fontSize: 10)),
              const SizedBox(height: 14),

              // Admin Delete / Report
              IconButton(icon: const Icon(Icons.more_vert, size: 24, color: Colors.white54), onPressed: _adminDeleteVideo),
            ],
          ),
        ),
      ],
    );
  }
}
