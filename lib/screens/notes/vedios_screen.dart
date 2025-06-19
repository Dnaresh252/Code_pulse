import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/youtube_video.dart';
import '../../services/youtube_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoPage extends StatefulWidget {
  final String topic;
  const VideoPage({super.key, required this.topic});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with TickerProviderStateMixin {
  bool _loading = true;
  List<YoutubeVideo> _videos = [];
  Map<String, bool> _savedStatus = {};
  YoutubePlayerController? _videoController;
  bool _isPlayerVisible = false;
  int _selectedVideoIndex = -1;
  bool _isCustomFullScreen = false; // Our custom fullscreen state
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadVideos();

    // Lock to portrait mode - we'll handle fullscreen manually
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    // Restore normal orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

    super.dispose();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await YoutubeService.fetchVideos(widget.topic);
      final savedVideos = await VideoStorage.getSavedVideos();

      if (mounted) {
        setState(() {
          _videos = videos;
          _savedStatus = {
            for (var video in _videos)
              video.videoId: savedVideos.any((saved) => saved.videoId == video.videoId)
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showErrorSnackBar('Failed to load videos');
      }
    }
  }

  void _playVideo(String videoId, int index) {
    if (!mounted) return;

    _videoController?.dispose();
    _videoController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        disableDragSeek: false,
      ),
    );

    setState(() {
      _selectedVideoIndex = index;
      _isPlayerVisible = true;
    });
    _slideController.forward();
    HapticFeedback.mediumImpact();
  }

  // Custom fullscreen toggle - NO plugin fullscreen
  void _toggleCustomFullscreen() {
    setState(() {
      _isCustomFullScreen = !_isCustomFullScreen;
    });

    if (_isCustomFullScreen) {
      // Hide system UI for fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // Allow landscape for fullscreen
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
    } else {
      // Show system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      // Force back to portrait
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    HapticFeedback.lightImpact();
  }

  Future<void> _closePlayer() async {
    // Exit custom fullscreen first if needed
    if (_isCustomFullScreen) {
      _toggleCustomFullscreen();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    await _slideController.reverse();
    if (mounted) {
      setState(() {
        _isPlayerVisible = false;
        _selectedVideoIndex = -1;
        _videoController = null;
      });
    }
  }

  Future<void> _toggleSaveVideo(YoutubeVideo video) async {
    try {
      final isSaved = _savedStatus[video.videoId] ?? false;
      isSaved
          ? await VideoStorage.removeVideo(video.videoId)
          : await VideoStorage.saveVideo(video);

      if (mounted) {
        setState(() {
          _savedStatus[video.videoId] = !isSaved;
        });
        _showSuccessSnackBar(isSaved ? 'Removed from saved' : 'Video saved!');
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorSnackBar('Save operation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Custom fullscreen overlay
    if (_isCustomFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Fullscreen video player
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildYouTubePlayer(),
              ),
            ),
            // Custom controls overlay
            Positioned(
              top: 40,
              right: 20,
              child: Row(
                children: [
                  if (_selectedVideoIndex >= 0)
                    _buildFloatingButton(
                      icon: _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      onTap: () => _toggleSaveVideo(_videos[_selectedVideoIndex]),
                      color: _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false
                          ? Colors.orange
                          : Colors.green,
                    ),
                  const SizedBox(width: 10),
                  _buildFloatingButton(
                    icon: Icons.fullscreen_exit,
                    onTap: _toggleCustomFullscreen,
                  ),
                  const SizedBox(width: 10),
                  _buildFloatingButton(
                    icon: Icons.close,
                    onTap: _closePlayer,
                  ),
                ],
              ),
            ),
            // Video title overlay
            if (_selectedVideoIndex >= 0)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _videos[_selectedVideoIndex].title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Normal view
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF415A77),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isPlayerVisible) _buildPlayerContent(),
              _buildVideoContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _videoController != null
          ? SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4AA).withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlayerHeader(),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildYouTubePlayer(),
                ),
              ),
            ],
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  // Separate YouTube player widget
  Widget _buildYouTubePlayer() {
    return YoutubePlayer(
      key: ValueKey(_videoController!.initialVideoId),
      controller: _videoController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: const Color(0xFF00D4AA),
      progressColors: const ProgressBarColors(
        playedColor: Color(0xFF00D4AA),
        handleColor: Color(0xFF00A8CC),
        bufferedColor: Colors.white30,
        backgroundColor: Colors.white10,
      ),
      onReady: () => debugPrint('Video ready'),
      bottomActions: [
        const CurrentPosition(),
        const SizedBox(width: 8),
        const ProgressBar(isExpanded: true),
        const SizedBox(width: 8),
        const RemainingDuration(),
        // Custom fullscreen button instead of plugin's
        IconButton(
          icon: const Icon(Icons.fullscreen, color: Colors.white),
          onPressed: _toggleCustomFullscreen,
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    return Expanded(
      child: _loading
          ? _buildLoadingState()
          : _videos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          return _buildVideoCard(
            video,
            index,
            _selectedVideoIndex == index,
            _savedStatus[video.videoId] ?? false,
          );
        },
      ),
    );
  }

  Widget _buildVideoCard(YoutubeVideo video, int index, bool isSelected, bool isSaved) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF00D4AA).withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _playVideo(video.videoId, index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildVideoThumbnail(video, isSelected, isSaved),
              const SizedBox(width: 16),
              Expanded(child: _buildVideoInfo(video, index, isSelected)),
              _buildSaveButton(video, isSaved),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(YoutubeVideo video, bool isSelected, bool isSaved) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            video.thumbnailUrl,
            width: 120,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              height: 80,
              color: Colors.grey.withOpacity(0.3),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        if (isSaved)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark, size: 14, color: Colors.white),
            ),
          ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoInfo(YoutubeVideo video, int index, bool isSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PLAYING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          video.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.touch_app, size: 14, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              'Tap to play',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton(YoutubeVideo video, bool isSaved) {
    return GestureDetector(
      onTap: () => _toggleSaveVideo(video),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSaved
                ? [Colors.orange, Colors.orange.shade600]
                : [Colors.green, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isSaved ? Colors.orange : Colors.green).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    if (_selectedVideoIndex < 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D4AA).withOpacity(0.2),
            const Color(0xFF00A8CC).withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_filled, color: Color(0xFF00D4AA), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _videos[_selectedVideoIndex].title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildSaveButton(_videos[_selectedVideoIndex],
              _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleCustomFullscreen,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _closePlayer,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00D4AA)),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learning Videos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topic: ${widget.topic}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_videos.isNotEmpty && !_isPlayerVisible) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00D4AA).withOpacity(0.2),
                    const Color(0xFF00A8CC).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_library, color: Color(0xFF00D4AA), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Top ${_videos.length} videos • Tap to play',
                    style: const TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Videos...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, size: 60, color: Colors.orange),
          const SizedBox(height: 20),
          const Text(
            'No Videos Found',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'No videos available for "${widget.topic}"',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class SavedVideoItem {
  final String videoId;
  final String title;
  final String link;

  SavedVideoItem({
    required this.videoId,
    required this.title,
    required this.link,
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'link': link,
  };

  factory SavedVideoItem.fromJson(Map<String, dynamic> json) => SavedVideoItem(
    videoId: json['videoId'] ?? '',
    title: json['title'] ?? '',
    link: json['link'] ?? '',
  );
}

class VideoStorage {
  // Save video - stores only title and link
  static Future<void> saveVideo(YoutubeVideo video) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // No user logged in
    final savedVideos = await getSavedVideos();

    // Create saved item with title and link only
    final savedItem = SavedVideoItem(
      videoId: video.videoId,
      title: video.title,
      link: 'https://youtube.com/watch?v=${video.videoId}',
    );

    if (!savedVideos.any((v) => v.videoId == video.videoId)) {
      savedVideos.add(savedItem);
      final jsonList = savedVideos.map((v) => jsonEncode(v.toJson())).toList();
      await prefs.setStringList('${userId}_saved_videos', jsonList);
    }
  }

  static Future<void> removeVideo(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // No user logged in
    final savedVideos = await getSavedVideos();
    savedVideos.removeWhere((v) => v.videoId == videoId);
    final jsonList = savedVideos.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList('${userId}_saved_videos', jsonList);
  }

  // Returns List<SavedVideoItem> instead of List<YoutubeVideo>
  static Future<List<SavedVideoItem>> getSavedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return []; // No user logged in, return empty list
    final jsonList = prefs.getStringList('${userId}_saved_videos') ?? [];
    return jsonList.map((json) => SavedVideoItem.fromJson(jsonDecode(json))).toList();
  }

  static Future<bool> isVideoSaved(String videoId) async {
    final savedVideos = await getSavedVideos();
    return savedVideos.any((v) => v.videoId == videoId);
  }

  // Helper method to get saved videos count
  static Future<int> getSavedVideosCount() async {
    final savedVideos = await getSavedVideos();
    return savedVideos.length;
  }

  // Clear all saved videos
  static Future<void> clearAllSavedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return; // No user logged in
    await prefs.remove('${userId}_saved_videos');
  }
}




// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../models/youtube_video.dart';
// import '../../services/youtube_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class VideoPage extends StatefulWidget {
//   final String topic;
//   const VideoPage({super.key, required this.topic});
//
//   @override
//   State<VideoPage> createState() => _VideoPageState();
// }
//
// class _VideoPageState extends State<VideoPage> with TickerProviderStateMixin {
//   bool _loading = true;
//   List<YoutubeVideo> _videos = [];
//   Map<String, bool> _savedStatus = {};
//   YoutubePlayerController? _videoController;
//   bool _isPlayerVisible = false;
//   int _selectedVideoIndex = -1;
//   bool _isFullScreen = false;
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAnimations();
//     _loadVideos();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//   }
//
//   void _initAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, -1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOut,
//     ));
//     _fadeController.forward();
//   }
//
//   @override
//   void dispose() {
//     _videoController?.dispose();
//     _fadeController.dispose();
//     _slideController.dispose();
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     super.dispose();
//   }
//
//   Future<void> _loadVideos() async {
//     try {
//       final videos = await YoutubeService.fetchVideos(widget.topic);
//       final savedVideos = await VideoStorage.getSavedVideos();
//
//       if (mounted) {
//         setState(() {
//           _videos = videos;
//           _savedStatus = {
//             for (var video in _videos)
//               video.videoId: savedVideos.any((saved) => saved.videoId == video.videoId)
//           };
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _loading = false);
//         _showErrorSnackBar('Failed to load videos');
//       }
//     }
//   }
//
//   void _playVideo(String videoId, int index) {
//     if (!mounted) return;
//
//     _videoController?.dispose();
//     _videoController = YoutubePlayerController(
//       initialVideoId: videoId,
//       flags: const YoutubePlayerFlags(
//         autoPlay: true,
//         mute: false,
//         enableCaption: true,
//       ),
//     );
//
//     setState(() {
//       _selectedVideoIndex = index;
//       _isPlayerVisible = true;
//     });
//     _slideController.forward();
//     HapticFeedback.mediumImpact();
//   }
//
//   Future<void> _closePlayer() async {
//     await _slideController.reverse();
//     if (mounted) {
//       setState(() {
//         _isPlayerVisible = false;
//         _selectedVideoIndex = -1;
//         _videoController = null;
//       });
//     }
//   }
//
//   Future<void> _toggleSaveVideo(YoutubeVideo video) async {
//     try {
//       final isSaved = _savedStatus[video.videoId] ?? false;
//       isSaved
//           ? await VideoStorage.removeVideo(video.videoId)
//           : await VideoStorage.saveVideo(video);
//
//       if (mounted) {
//         setState(() {
//           _savedStatus[video.videoId] = !isSaved;
//         });
//         _showSuccessSnackBar(isSaved ? 'Removed from saved' : 'Video saved!');
//       }
//       HapticFeedback.lightImpact();
//     } catch (e) {
//       _showErrorSnackBar('Save operation failed');
//     }
//   }
//
//   void _handleFullscreenChange(bool isFullscreen) {
//     if (!mounted) return;
//
//     setState(() => _isFullScreen = isFullscreen);
//
//     if (isFullscreen) {
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//       SystemChrome.setPreferredOrientations([
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ]);
//     } else {
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
//           overlays: SystemUiOverlay.values);
//       SystemChrome.setPreferredOrientations([
//         DeviceOrientation.portraitUp,
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ]);
//       // Schedule a frame to ensure smooth transition
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) setState(() {});
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
//
//     if (_isFullScreen) {
//       return Scaffold(
//         backgroundColor: Colors.black,
//         body: SafeArea(
//           child: _buildPlayerContent(),
//         ),
//       );
//     }
//
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF0D1B2A),
//               Color(0xFF1B263B),
//               Color(0xFF415A77),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: Column(
//                   children: [
//                     if (!isLandscape || !_isPlayerVisible) _buildHeader(),
//                     if (_isPlayerVisible) _buildPlayerContent(),
//                     if (!isLandscape || !_isPlayerVisible) _buildVideoContent(),
//                   ],
//                 ),
//               ),
//               if (isLandscape && _isPlayerVisible && !_isFullScreen) ...[
//                 _buildFloatingButton(
//                   icon: Icons.close,
//                   onTap: _closePlayer,
//                   right: 16,
//                 ),
//                 if (_selectedVideoIndex >= 0)
//                   _buildFloatingButton(
//                     icon: _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false
//                         ? Icons.bookmark : Icons.bookmark_border,
//                     onTap: () => _toggleSaveVideo(_videos[_selectedVideoIndex]),
//                     right: 70,
//                     color: _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false
//                         ? Colors.orange : Colors.green,
//                   ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlayerContent() {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 300),
//       child: _videoController != null
//           ? YoutubePlayerBuilder(
//         onEnterFullScreen: () => _handleFullscreenChange(true),
//         onExitFullScreen: () => _handleFullscreenChange(false),
//         player: YoutubePlayer(
//           key: ValueKey(_videoController!.initialVideoId),
//           controller: _videoController!,
//           showVideoProgressIndicator: true,
//           progressIndicatorColor: const Color(0xFF00D4AA),
//           progressColors: const ProgressBarColors(
//             playedColor: Color(0xFF00D4AA),
//             handleColor: Color(0xFF00A8CC),
//             bufferedColor: Colors.white30,
//             backgroundColor: Colors.white10,
//           ),
//           onReady: () => debugPrint('Video ready'),
//           bottomActions: [
//             const CurrentPosition(),
//             const SizedBox(width: 8),
//             const ProgressBar(isExpanded: true),
//             const SizedBox(width: 8),
//             const RemainingDuration(),
//             const FullScreenButton(),
//           ],
//         ),
//         builder: (context, player) {
//           return _isFullScreen
//               ? player
//               : SlideTransition(
//             position: _slideAnimation,
//             child: Container(
//               margin: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: const Color(0xFF00D4AA).withOpacity(0.3),
//                   width: 2,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF00D4AA).withOpacity(0.2),
//                     blurRadius: 15,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (!_isFullScreen) _buildPlayerHeader(),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(12),
//                     child: AspectRatio(
//                       aspectRatio: 16/9,
//                       child: player,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       )
//           : const SizedBox.shrink(),
//     );
//   }
//
//   Widget _buildVideoContent() {
//     return Expanded(
//       child: _loading
//           ? _buildLoadingState()
//           : _videos.isEmpty
//           ? _buildEmptyState()
//           : ListView.builder(
//         padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//         itemCount: _videos.length,
//         itemBuilder: (context, index) {
//           final video = _videos[index];
//           return _buildVideoCard(
//             video,
//             index,
//             _selectedVideoIndex == index,
//             _savedStatus[video.videoId] ?? false,
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildVideoCard(YoutubeVideo video, int index, bool isSelected, bool isSaved) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       color: Colors.white.withOpacity(0.05),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: isSelected
//               ? const Color(0xFF00D4AA).withOpacity(0.5)
//               : Colors.white.withOpacity(0.2),
//           width: isSelected ? 2 : 1,
//         ),
//       ),
//       elevation: isSelected ? 8 : 2,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () => _playVideo(video.videoId, index),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               _buildVideoThumbnail(video, isSelected, isSaved),
//               const SizedBox(width: 16),
//               Expanded(child: _buildVideoInfo(video, index, isSelected)),
//               _buildSaveButton(video, isSaved),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildVideoThumbnail(YoutubeVideo video, bool isSelected, bool isSaved) {
//     return Stack(
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Image.network(
//             video.thumbnailUrl,
//             width: 120,
//             height: 80,
//             fit: BoxFit.cover,
//             errorBuilder: (_, __, ___) => Container(
//               width: 120,
//               height: 80,
//               color: Colors.grey.withOpacity(0.3),
//               child: const Icon(Icons.broken_image, color: Colors.grey),
//             ),
//           ),
//         ),
//         if (isSaved)
//           Positioned(
//             top: 8,
//             right: 8,
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: const BoxDecoration(
//                 color: Colors.orange,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.bookmark, size: 14, color: Colors.white),
//             ),
//           ),
//         Positioned.fill(
//           child: Center(
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.6),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isSelected ? Icons.pause : Icons.play_arrow,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildVideoInfo(YoutubeVideo video, int index, bool isSelected) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                 ),
//                 borderRadius: BorderRadius.all(Radius.circular(8)),
//               ),
//               child: Text(
//                 '${index + 1}',
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             if (isSelected) ...[
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF00D4AA),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'PLAYING',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//         const SizedBox(height: 8),
//         Text(
//           video.title,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             height: 1.3,
//           ),
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Icon(Icons.touch_app, size: 14, color: Colors.white.withOpacity(0.7)),
//             const SizedBox(width: 6),
//             Text(
//               'Tap to play',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.7),
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSaveButton(YoutubeVideo video, bool isSaved) {
//     return GestureDetector(
//       onTap: () => _toggleSaveVideo(video),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isSaved
//                 ? [Colors.orange, Colors.orange.shade600]
//                 : [Colors.green, Colors.green.shade600],
//           ),
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: (isSaved ? Colors.orange : Colors.green).withOpacity(0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Icon(
//           isSaved ? Icons.bookmark : Icons.bookmark_border,
//           color: Colors.white,
//           size: 20,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFloatingButton({
//     required IconData icon,
//     required VoidCallback onTap,
//     required double right,
//     Color color = Colors.white,
//   }) {
//     return Positioned(
//       top: 16,
//       right: right,
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.2),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: color.withOpacity(0.5)),
//           ),
//           child: Icon(icon, color: color, size: 20),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlayerHeader() {
//     if (_selectedVideoIndex < 0) return const SizedBox.shrink();
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color(0xFF00D4AA).withOpacity(0.2),
//             const Color(0xFF00A8CC).withOpacity(0.1),
//           ],
//         ),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.play_circle_filled, color: Color(0xFF00D4AA), size: 24),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               _videos[_selectedVideoIndex].title,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           _buildSaveButton(_videos[_selectedVideoIndex],
//               _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: _closePlayer,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.close, color: Colors.white, size: 20),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00D4AA)),
//                 onPressed: () => Navigator.pop(context),
//                 style: IconButton.styleFrom(
//                   backgroundColor: Colors.white.withOpacity(0.1),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     side: BorderSide(color: Colors.white.withOpacity(0.2)),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Learning Videos',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Topic: ${widget.topic}',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.7),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           if (_videos.isNotEmpty && !_isPlayerVisible) ...[
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     const Color(0xFF00D4AA).withOpacity(0.2),
//                     const Color(0xFF00A8CC).withOpacity(0.1),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: const Color(0xFF00D4AA).withOpacity(0.3),
//                   width: 1,
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.video_library, color: Color(0xFF00D4AA), size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Top ${_videos.length} videos • Tap to play',
//                     style: const TextStyle(
//                       color: Color(0xFF00D4AA),
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'Loading Videos...',
//             style: TextStyle(color: Colors.white, fontSize: 18),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.videocam_off, size: 60, color: Colors.orange),
//           const SizedBox(height: 20),
//           const Text(
//             'No Videos Found',
//             style: TextStyle(color: Colors.white, fontSize: 20),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'No videos available for "${widget.topic}"',
//             style: TextStyle(color: Colors.white.withOpacity(0.7)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showErrorSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
//
//   void _showSuccessSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
// }class SavedVideoItem {
//   final String videoId;
//   final String title;
//   final String link;
//
//   SavedVideoItem({
//     required this.videoId,
//     required this.title,
//     required this.link,
//   });
//
//   Map<String, dynamic> toJson() => {
//     'videoId': videoId,
//     'title': title,
//     'link': link,
//   };
//
//   factory SavedVideoItem.fromJson(Map<String, dynamic> json) => SavedVideoItem(
//     videoId: json['videoId'] ?? '',
//     title: json['title'] ?? '',
//     link: json['link'] ?? '',
//   );
// }
//
//
//
//
// class VideoStorage {
//   // Save video - stores only title and link
//   static Future<void> saveVideo(YoutubeVideo video) async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return; // No user logged in
//     final savedVideos = await getSavedVideos();
//
//     // Create saved item with title and link only
//     final savedItem = SavedVideoItem(
//       videoId: video.videoId,
//       title: video.title,
//       link: 'https://youtube.com/watch?v=${video.videoId}',
//     );
//
//     if (!savedVideos.any((v) => v.videoId == video.videoId)) {
//       savedVideos.add(savedItem);
//       final jsonList = savedVideos.map((v) => jsonEncode(v.toJson())).toList();
//       await prefs.setStringList('${userId}_saved_videos', jsonList);
//     }
//   }
//
//   static Future<void> removeVideo(String videoId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return; // No user logged in
//     final savedVideos = await getSavedVideos();
//     savedVideos.removeWhere((v) => v.videoId == videoId);
//     final jsonList = savedVideos.map((v) => jsonEncode(v.toJson())).toList();
//     await prefs.setStringList('${userId}_saved_videos', jsonList);
//   }
//
//   // Returns List<SavedVideoItem> instead of List<YoutubeVideo>
//   static Future<List<SavedVideoItem>> getSavedVideos() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return []; // No user logged in, return empty list
//     final jsonList = prefs.getStringList('${userId}_saved_videos') ?? [];
//     return jsonList.map((json) => SavedVideoItem.fromJson(jsonDecode(json))).toList();
//   }
//
//   static Future<bool> isVideoSaved(String videoId) async {
//     final savedVideos = await getSavedVideos();
//     return savedVideos.any((v) => v.videoId == videoId);
//   }
//
//   // Helper method to get saved videos count
//   static Future<int> getSavedVideosCount() async {
//     final savedVideos = await getSavedVideos();
//     return savedVideos.length;
//   }
//
//   // Clear all saved videos
//   static Future<void> clearAllSavedVideos() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return; // No user logged in
//     await prefs.remove('${userId}_saved_videos');
//   }
// }
//
//
//
// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import '../../models/youtube_video.dart';
// // import '../../services/youtube_service.dart';
// // import 'package:firebase_auth/firebase_auth.dart';  // Add this line
// //
// // // Storage Service for Save Functionality
// // class SavedVideoItem {
// //   final String videoId;
// //   final String title;
// //   final String link;
// //
// //   SavedVideoItem({
// //     required this.videoId,
// //     required this.title,
// //     required this.link,
// //   });
// //
// //   Map<String, dynamic> toJson() => {
// //     'videoId': videoId,
// //     'title': title,
// //     'link': link,
// //   };
// //
// //   factory SavedVideoItem.fromJson(Map<String, dynamic> json) => SavedVideoItem(
// //     videoId: json['videoId'] ?? '',
// //     title: json['title'] ?? '',
// //     link: json['link'] ?? '',
// //   );
// // }
// //
// // class VideoStorage {
// //
// //
// //   // Save video - stores only title and link
// //
// //
// //   static Future<void> saveVideo(YoutubeVideo video) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final userId = FirebaseAuth.instance.currentUser?.uid;
// //     if (userId == null) return; // No user logged in
// //     final savedVideos = await getSavedVideos();
// //
// //     // Create saved item with title and link only
// //     final savedItem = SavedVideoItem(
// //       videoId: video.videoId,
// //       title: video.title,
// //       link: 'https://youtube.com/watch?v=${video.videoId}',
// //     );
// //
// //     if (!savedVideos.any((v) => v.videoId == video.videoId)) {
// //       savedVideos.add(savedItem);
// //       final jsonList = savedVideos.map((v) => jsonEncode(v.toJson())).toList();
// //       await prefs.setStringList('${userId}_saved_videos', jsonList);
// //     }
// //   }
// //
// //   static Future<void> removeVideo(String videoId) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final userId = FirebaseAuth.instance.currentUser?.uid;
// //     if (userId == null) return; // No user logged in
// //     final savedVideos = await getSavedVideos();
// //     savedVideos.removeWhere((v) => v.videoId == videoId);
// //     final jsonList = savedVideos.map((v) => jsonEncode(v.toJson())).toList();
// //     await prefs.setStringList('${userId}_saved_videos', jsonList);
// //   }
// //
// //   // Fixed: Returns List<SavedVideoItem> instead of List<YoutubeVideo>
// //   static Future<List<SavedVideoItem>> getSavedVideos() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final userId = FirebaseAuth.instance.currentUser?.uid;
// //     if (userId == null) return []; // No user logged in, return empty list
// //     final jsonList = prefs.getStringList('${userId}_saved_videos') ?? [];
// //     return jsonList.map((json) => SavedVideoItem.fromJson(jsonDecode(json))).toList();
// //   }
// //
// //   static Future<bool> isVideoSaved(String videoId) async {
// //     final savedVideos = await getSavedVideos();
// //     return savedVideos.any((v) => v.videoId == videoId);
// //   }
// //
// //   // Helper method to get saved videos count
// //   static Future<int> getSavedVideosCount() async {
// //     final savedVideos = await getSavedVideos();
// //     return savedVideos.length;
// //   }
// //
// //   // Clear all saved videos
// //   static Future<void> clearAllSavedVideos() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final userId = FirebaseAuth.instance.currentUser?.uid;
// //     if (userId == null) return; // No user logged in
// //     await prefs.remove('${userId}_saved_videos');
// //   }
// // }
// //
// // class VideoPage extends StatefulWidget {
// //   final String topic;
// //   const VideoPage({super.key, required this.topic});
// //
// //   @override
// //   State<VideoPage> createState() => _VideoPageState();
// // }
// //
// // class _VideoPageState extends State<VideoPage> with TickerProviderStateMixin {
// //   bool _loading = true;
// //   List<YoutubeVideo> _videos = [];
// //   Map<String, bool> _savedStatus = {}; // Track save status for each video
// //   YoutubePlayerController? _videoController;
// //   bool _isPlayerVisible = false;
// //   int _selectedVideoIndex = -1;
// //
// //   late AnimationController _fadeController;
// //   late AnimationController _slideController;
// //   late Animation<double> _fadeAnimation;
// //   late Animation<Offset> _slideAnimation;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadVideos();
// //
// //     _fadeController = AnimationController(
// //       duration: const Duration(milliseconds: 800),
// //       vsync: this,
// //     );
// //
// //     _slideController = AnimationController(
// //       duration: const Duration(milliseconds: 600),
// //       vsync: this,
// //     );
// //
// //     _fadeAnimation = CurvedAnimation(
// //       parent: _fadeController,
// //       curve: Curves.easeIn,
// //     );
// //
// //     _slideAnimation = Tween<Offset>(
// //       begin: const Offset(0, -1),
// //       end: Offset.zero,
// //     ).animate(CurvedAnimation(
// //       parent: _slideController,
// //       curve: Curves.easeOutBack,
// //     ));
// //
// //     SystemChrome.setPreferredOrientations([
// //       DeviceOrientation.portraitUp,
// //     ]);
// //
// //     _fadeController.forward();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _videoController?.dispose();
// //     _fadeController.dispose();
// //     _slideController.dispose();
// //     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
// //     super.dispose();
// //   }
// //
// //   // Fixed: Proper type handling for saved videos
// //   Future<void> _loadVideos() async {
// //     try {
// //       final [videos, savedVideos] = await Future.wait([
// //         YoutubeService.fetchVideos(widget.topic),
// //         VideoStorage.getSavedVideos(),
// //       ]);
// //
// //       if (mounted) {
// //         setState(() {
// //           _videos = videos as List<YoutubeVideo>;
// //
// //           // Initialize save status for each video
// //           _savedStatus = {};
// //           for (var video in _videos) {
// //             _savedStatus[video.videoId] = (savedVideos as List<SavedVideoItem>)
// //                 .any((saved) => saved.videoId == video.videoId);
// //           }
// //
// //           _loading = false;
// //         });
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         setState(() => _loading = false);
// //         _showErrorSnackBar('Failed to load videos: $e');
// //       }
// //     }
// //   }
// //
// //   void _playVideo(String videoId, int index) {
// //     if (mounted) {
// //       try {
// //         _videoController?.dispose();
// //
// //         _videoController = YoutubePlayerController(
// //           initialVideoId: videoId,
// //           flags: const YoutubePlayerFlags(
// //             autoPlay: true,
// //             mute: false,
// //             enableCaption: true,
// //             isLive: false,
// //             forceHD: false,
// //             startAt: 0,
// //             controlsVisibleAtStart: true,
// //             hideControls: false,
// //             disableDragSeek: false,
// //             loop: false,
// //             useHybridComposition: true,
// //           ),
// //         );
// //
// //         setState(() {
// //           _selectedVideoIndex = index;
// //           _isPlayerVisible = true;
// //         });
// //
// //         _slideController.forward();
// //         HapticFeedback.mediumImpact();
// //       } catch (e) {
// //         _showErrorSnackBar('Could not play video: $e');
// //       }
// //     }
// //   }
// //
// //   // Fixed: Removed incorrect type casting
// //   void _closePlayer() {
// //     _slideController.reverse().then((_) {
// //       if (mounted) {
// //         setState(() {
// //           _isPlayerVisible = false;
// //           _selectedVideoIndex = -1;
// //         });
// //         _videoController?.dispose();
// //         _videoController = null;
// //       }
// //     });
// //   }
// //
// //   // Save functionality
// //   Future<void> _toggleSaveVideo(YoutubeVideo video) async {
// //     try {
// //       final isCurrentlySaved = _savedStatus[video.videoId] ?? false;
// //
// //       if (isCurrentlySaved) {
// //         await VideoStorage.removeVideo(video.videoId);
// //         setState(() {
// //           _savedStatus[video.videoId] = false;
// //         });
// //         _showSuccessSnackBar('Video removed from saved');
// //       } else {
// //         await VideoStorage.saveVideo(video);
// //         setState(() {
// //           _savedStatus[video.videoId] = true;
// //         });
// //         _showSuccessSnackBar('Video saved successfully!');
// //       }
// //
// //       HapticFeedback.lightImpact();
// //     } catch (e) {
// //       _showErrorSnackBar('Save operation failed');
// //     }
// //   }
// //
// //   void _showErrorSnackBar(String message) {
// //     if (mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(message),
// //           backgroundColor: Colors.red,
// //           behavior: SnackBarBehavior.floating,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //         ),
// //       );
// //     }
// //   }
// //
// //   void _showSuccessSnackBar(String message) {
// //     if (mounted) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(message),
// //           backgroundColor: Colors.green,
// //           behavior: SnackBarBehavior.floating,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //         ),
// //       );
// //     }
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //             colors: [
// //               Color(0xFF0D1B2A),
// //               Color(0xFF1B263B),
// //               Color(0xFF415A77),
// //             ],
// //             stops: [0.0, 0.5, 1.0],
// //           ),
// //         ),
// //         child: SafeArea(
// //           child: FadeTransition(
// //             opacity: _fadeAnimation,
// //             child: Column(
// //               children: [
// //                 _buildHeader(),
// //                 if (_isPlayerVisible) _buildEmbeddedPlayer(),
// //                 Expanded(
// //                   child: _loading
// //                       ? _buildLoadingState()
// //                       : _videos.isEmpty
// //                       ? _buildEmptyState()
// //                       : _buildVideoList(),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildHeader() {
// //     return Padding(
// //       padding: const EdgeInsets.all(20.0),
// //       child: Column(
// //         children: [
// //           Row(
// //             children: [
// //               GestureDetector(
// //                 onTap: () => Navigator.pop(context),
// //                 child: Container(
// //                   padding: const EdgeInsets.all(12),
// //                   decoration: BoxDecoration(
// //                     gradient: LinearGradient(
// //                       colors: [
// //                         Colors.white.withOpacity(0.1),
// //                         Colors.white.withOpacity(0.05),
// //                       ],
// //                     ),
// //                     borderRadius: BorderRadius.circular(16),
// //                     border: Border.all(
// //                       color: Colors.white.withOpacity(0.2),
// //                       width: 1,
// //                     ),
// //                   ),
// //                   child: const Icon(
// //                     Icons.arrow_back_ios,
// //                     color: Color(0xFF00D4AA),
// //                     size: 20,
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(width: 16),
// //               Expanded(
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     ShaderMask(
// //                       shaderCallback: (bounds) => const LinearGradient(
// //                         colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
// //                         stops: [0.0, 0.5, 1.0],
// //                       ).createShader(bounds),
// //                       child: const Text(
// //                         'Learning Videos',
// //                         style: TextStyle(
// //                           color: Colors.white,
// //                           fontSize: 24,
// //                           fontWeight: FontWeight.bold,
// //                           letterSpacing: 0.5,
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 4),
// //                     Text(
// //                       'Topic: ${widget.topic}',
// //                       style: TextStyle(
// //                         color: Colors.white.withOpacity(0.7),
// //                         fontSize: 14,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           ),
// //           if (_videos.isNotEmpty && !_isPlayerVisible) ...[
// //             const SizedBox(height: 20),
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     const Color(0xFF00D4AA).withOpacity(0.2),
// //                     const Color(0xFF00A8CC).withOpacity(0.1),
// //                   ],
// //                 ),
// //                 borderRadius: BorderRadius.circular(16),
// //                 border: Border.all(
// //                   color: const Color(0xFF00D4AA).withOpacity(0.3),
// //                   width: 1,
// //                 ),
// //               ),
// //               child: Row(
// //                 children: [
// //                   const Icon(
// //                     Icons.video_library,
// //                     color: Color(0xFF00D4AA),
// //                     size: 20,
// //                   ),
// //                   const SizedBox(width: 8),
// //                   Text(
// //                     'Top ${_videos.length} videos • Tap to play',
// //                     style: const TextStyle(
// //                       color: Color(0xFF00D4AA),
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.w600,
// //                     ),
// //                   ),
// //
// //                   // Show saved count
// //                   // if (_savedStatus.values.any((saved) => saved))
// //                   //   Container(
// //                   //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                   //     decoration: BoxDecoration(
// //                   //       color: Colors.orange.withOpacity(0.2),
// //                   //       borderRadius: BorderRadius.circular(12),
// //                   //       border: Border.all(color: Colors.orange.withOpacity(0.5)),
// //                   //     ),
// //                   //     child: Row(
// //                   //       mainAxisSize: MainAxisSize.min,
// //                   //       children: [
// //                   //         const Icon(Icons.bookmark, color: Colors.orange, size: 14),
// //                   //         const SizedBox(width: 4),
// //                   //         Text(
// //                   //           '${_savedStatus.values.where((saved) => saved).length} saved',
// //                   //           style: const TextStyle(
// //                   //             color: Colors.orange,
// //                   //             fontSize: 12,
// //                   //             fontWeight: FontWeight.bold,
// //                   //           ),
// //                   //         ),
// //                   //       ],
// //                   //     ),
// //                   //   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildEmbeddedPlayer() {
// //     if (_videoController == null) return const SizedBox.shrink();
// //
// //     return SlideTransition(
// //       position: _slideAnimation,
// //       child: Container(
// //         margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [
// //               Colors.white.withOpacity(0.1),
// //               Colors.white.withOpacity(0.05),
// //             ],
// //           ),
// //           borderRadius: BorderRadius.circular(20),
// //           border: Border.all(
// //             color: const Color(0xFF00D4AA).withOpacity(0.3),
// //             width: 2,
// //           ),
// //           boxShadow: [
// //             BoxShadow(
// //               color: const Color(0xFF00D4AA).withOpacity(0.2),
// //               blurRadius: 15,
// //               offset: const Offset(0, 8),
// //             ),
// //           ],
// //         ),
// //         child: Column(
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [
// //                     const Color(0xFF00D4AA).withOpacity(0.2),
// //                     const Color(0xFF00A8CC).withOpacity(0.1),
// //                   ],
// //                 ),
// //                 borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
// //               ),
// //               child: Row(
// //                 children: [
// //                   const Icon(
// //                     Icons.play_circle_filled,
// //                     color: Color(0xFF00D4AA),
// //                     size: 24,
// //                   ),
// //                   const SizedBox(width: 12),
// //                   Expanded(
// //                     child: Text(
// //                       _selectedVideoIndex >= 0
// //                           ? _videos[_selectedVideoIndex].title
// //                           : 'Now Playing',
// //                       style: const TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 16,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                       maxLines: 1,
// //                       overflow: TextOverflow.ellipsis,
// //                     ),
// //                   ),
// //                   // Save button in player header
// //                   if (_selectedVideoIndex >= 0)
// //                     GestureDetector(
// //                       onTap: () => _toggleSaveVideo(_videos[_selectedVideoIndex]),
// //                       child: Container(
// //                         padding: const EdgeInsets.all(8),
// //                         margin: const EdgeInsets.only(right: 8),
// //                         decoration: BoxDecoration(
// //                           color: (_savedStatus[_videos[_selectedVideoIndex].videoId] ?? false)
// //                               ? Colors.orange.withOpacity(0.2)
// //                               : Colors.green.withOpacity(0.2),
// //                           borderRadius: BorderRadius.circular(12),
// //                           border: Border.all(
// //                             color: (_savedStatus[_videos[_selectedVideoIndex].videoId] ?? false)
// //                                 ? Colors.orange
// //                                 : Colors.green,
// //                           ),
// //                         ),
// //                         child: Icon(
// //                           (_savedStatus[_videos[_selectedVideoIndex].videoId] ?? false)
// //                               ? Icons.bookmark
// //                               : Icons.bookmark_border,
// //                           color: (_savedStatus[_videos[_selectedVideoIndex].videoId] ?? false)
// //                               ? Colors.orange
// //                               : Colors.green,
// //                           size: 18,
// //                         ),
// //                       ),
// //                     ),
// //                   GestureDetector(
// //                     onTap: _closePlayer,
// //                     child: Container(
// //                       padding: const EdgeInsets.all(8),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: const Icon(
// //                         Icons.close,
// //                         color: Colors.white,
// //                         size: 20,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Container(
// //               padding: const EdgeInsets.all(8),
// //               child: ClipRRect(
// //                 borderRadius: BorderRadius.circular(12),
// //                 child: YoutubePlayerBuilder(
// //                   onEnterFullScreen: () {
// //                     SystemChrome.setPreferredOrientations([
// //                       DeviceOrientation.landscapeLeft,
// //                       DeviceOrientation.landscapeRight,
// //                     ]);
// //                   },
// //                   onExitFullScreen: () {
// //                     SystemChrome.setPreferredOrientations([
// //                       DeviceOrientation.portraitUp,
// //                     ]);
// //                   },
// //                   player: YoutubePlayer(
// //                     controller: _videoController!,
// //                     showVideoProgressIndicator: true,
// //                     progressIndicatorColor: const Color(0xFF00D4AA),
// //                     progressColors: ProgressBarColors(
// //                       playedColor: const Color(0xFF00D4AA),
// //                       handleColor: const Color(0xFF00A8CC),
// //                       bufferedColor: Colors.white.withOpacity(0.3),
// //                       backgroundColor: Colors.white.withOpacity(0.1),
// //                     ),
// //                     onReady: () {
// //                       debugPrint('Video is ready to play');
// //                     },
// //                     onEnded: (data) {
// //                       debugPrint('Video ended');
// //                     },
// //                     bottomActions: [
// //                       const CurrentPosition(),
// //                       const SizedBox(width: 10),
// //                       ProgressBar(
// //                         isExpanded: true,
// //                         colors: ProgressBarColors(
// //                           playedColor: const Color(0xFF00D4AA),
// //                           handleColor: const Color(0xFF00A8CC),
// //                           bufferedColor: Colors.white.withOpacity(0.3),
// //                           backgroundColor: Colors.white.withOpacity(0.1),
// //                         ),
// //                       ),
// //                       const SizedBox(width: 10),
// //                       const RemainingDuration(),
// //                       const SizedBox(width: 10),
// //                       const FullScreenButton(),
// //                     ],
// //                   ),
// //                   builder: (context, player) {
// //                     return AspectRatio(
// //                       aspectRatio: 16 / 9,
// //                       child: player,
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildVideoList() {
// //     return ListView.builder(
// //       padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
// //       itemCount: _videos.length,
// //       itemBuilder: (context, index) {
// //         final video = _videos[index];
// //         final isSelected = _selectedVideoIndex == index;
// //         final isSaved = _savedStatus[video.videoId] ?? false;
// //         return _buildVideoCard(video, index, isSelected, isSaved);
// //       },
// //     );
// //   }
// //
// //   Widget _buildVideoCard(YoutubeVideo video, int index, bool isSelected, bool isSaved) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 16),
// //       decoration: BoxDecoration(
// //         gradient: LinearGradient(
// //           colors: isSelected
// //               ? [
// //             const Color(0xFF00D4AA).withOpacity(0.2),
// //             const Color(0xFF00A8CC).withOpacity(0.1),
// //           ]
// //               : [
// //             Colors.white.withOpacity(0.1),
// //             Colors.white.withOpacity(0.05),
// //           ],
// //         ),
// //         borderRadius: BorderRadius.circular(16),
// //         border: Border.all(
// //           color: isSelected
// //               ? const Color(0xFF00D4AA).withOpacity(0.5)
// //               : Colors.white.withOpacity(0.2),
// //           width: isSelected ? 2 : 1,
// //         ),
// //         boxShadow: [
// //           BoxShadow(
// //             color: isSelected
// //                 ? const Color(0xFF00D4AA).withOpacity(0.2)
// //                 : Colors.black.withOpacity(0.1),
// //             blurRadius: isSelected ? 12 : 6,
// //             offset: Offset(0, isSelected ? 6 : 3),
// //           ),
// //         ],
// //       ),
// //       child: Material(
// //         color: Colors.transparent,
// //         child: InkWell(
// //           borderRadius: BorderRadius.circular(16),
// //           onTap: () => _playVideo(video.videoId, index),
// //           child: Padding(
// //             padding: const EdgeInsets.all(16),
// //             child: Row(
// //               children: [
// //                 // Thumbnail with save indicator
// //                 Stack(
// //                   children: [
// //                     ClipRRect(
// //                       borderRadius: BorderRadius.circular(12),
// //                       child: Stack(
// //                         alignment: Alignment.center,
// //                         children: [
// //                           Image.network(
// //                             video.thumbnailUrl,
// //                             width: 120,
// //                             height: 80,
// //                             fit: BoxFit.cover,
// //                             errorBuilder: (context, error, stackTrace) => Container(
// //                               width: 120,
// //                               height: 80,
// //                               color: Colors.grey.withOpacity(0.3),
// //                               child: const Icon(
// //                                 Icons.broken_image,
// //                                 color: Colors.grey,
// //                                 size: 30,
// //                               ),
// //                             ),
// //                           ),
// //                           Container(
// //                             decoration: BoxDecoration(
// //                               color: Colors.black.withOpacity(0.6),
// //                               shape: BoxShape.circle,
// //                             ),
// //                             padding: const EdgeInsets.all(8),
// //                             child: Icon(
// //                               isSelected ? Icons.pause : Icons.play_arrow,
// //                               color: Colors.white,
// //                               size: 20,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     // Save indicator on thumbnail
// //                     if (isSaved)
// //                       Positioned(
// //                         top: 8,
// //                         right: 8,
// //                         child: Container(
// //                           padding: const EdgeInsets.all(4),
// //                           decoration: BoxDecoration(
// //                             color: Colors.orange,
// //                             shape: BoxShape.circle,
// //                             boxShadow: [
// //                               BoxShadow(
// //                                 color: Colors.orange.withOpacity(0.3),
// //                                 blurRadius: 8,
// //                                 offset: const Offset(0, 2),
// //                               ),
// //                             ],
// //                           ),
// //                           child: const Icon(
// //                             Icons.bookmark,
// //                             color: Colors.white,
// //                             size: 14,
// //                           ),
// //                         ),
// //                       ),
// //                   ],
// //                 ),
// //                 const SizedBox(width: 16),
// //                 // Video Info
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Row(
// //                         children: [
// //                           Container(
// //                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                             decoration: const BoxDecoration(
// //                               gradient: LinearGradient(
// //                                 colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
// //                               ),
// //                               borderRadius: BorderRadius.all(Radius.circular(8)),
// //                             ),
// //                             child: Text(
// //                               '${index + 1}',
// //                               style: const TextStyle(
// //                                 color: Colors.white,
// //                                 fontSize: 12,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ),
// //                           if (isSelected) ...[
// //                             const SizedBox(width: 8),
// //                             Container(
// //                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// //                               decoration: BoxDecoration(
// //                                 color: const Color(0xFF00D4AA),
// //                                 borderRadius: BorderRadius.circular(8),
// //                               ),
// //                               child: const Text(
// //                                 'PLAYING',
// //                                 style: TextStyle(
// //                                   color: Colors.white,
// //                                   fontSize: 10,
// //                                   fontWeight: FontWeight.bold,
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //
// //
// //                         ],
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         video.title,
// //                         style: const TextStyle(
// //                           color: Colors.white,
// //                           fontSize: 14,
// //                           fontWeight: FontWeight.w600,
// //                           height: 1.3,
// //                         ),
// //                         maxLines: 2,
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Row(
// //                         children: [
// //                           Icon(
// //                             Icons.touch_app,
// //                             size: 14,
// //                             color: Colors.white.withOpacity(0.7),
// //                           ),
// //                           const SizedBox(width: 6),
// //                           Expanded(
// //                             child: Text(
// //                               'Tap to play • Tap save to bookmark',
// //                               style: TextStyle(
// //                                 color: Colors.white.withOpacity(0.7),
// //                                 fontSize: 12,
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(width: 12),
// //                 // Save Button
// //                 GestureDetector(
// //                   onTap: () => _toggleSaveVideo(video),
// //                   child: Container(
// //                     padding: const EdgeInsets.all(12),
// //                     decoration: BoxDecoration(
// //                       gradient: LinearGradient(
// //                         colors: isSaved
// //                             ? [Colors.orange, Colors.orange.shade600]
// //                             : [Colors.green, Colors.green.shade600],
// //                       ),
// //                       borderRadius: BorderRadius.circular(12),
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: (isSaved ? Colors.orange : Colors.green).withOpacity(0.3),
// //                           blurRadius: 8,
// //                           offset: const Offset(0, 4),
// //                         ),
// //                       ],
// //                     ),
// //                     child: Icon(
// //                       isSaved ? Icons.bookmark : Icons.bookmark_border,
// //                       color: Colors.white,
// //                       size: 20,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildLoadingState() {
// //     return Center(
// //       child: Container(
// //         padding: const EdgeInsets.all(40),
// //         margin: const EdgeInsets.all(20),
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [
// //               Colors.white.withOpacity(0.15),
// //               Colors.white.withOpacity(0.08),
// //             ],
// //           ),
// //           borderRadius: BorderRadius.circular(24),
// //           border: Border.all(
// //             color: Colors.white.withOpacity(0.2),
// //             width: 1,
// //           ),
// //         ),
// //         child: const Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             CircularProgressIndicator(
// //               valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
// //               strokeWidth: 3,
// //             ),
// //             SizedBox(height: 24),
// //             Text(
// //               'Loading Videos...',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildEmptyState() {
// //     return Center(
// //       child: Container(
// //         padding: const EdgeInsets.all(40),
// //         margin: const EdgeInsets.all(20),
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [
// //               Colors.white.withOpacity(0.1),
// //               Colors.white.withOpacity(0.05),
// //             ],
// //           ),
// //           borderRadius: BorderRadius.circular(24),
// //           border: Border.all(
// //             color: Colors.white.withOpacity(0.2),
// //             width: 1,
// //           ),
// //         ),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Icon(
// //               Icons.videocam_off,
// //               size: 60,
// //               color: Colors.orange,
// //             ),
// //             const SizedBox(height: 24),
// //             const Text(
// //               'No Videos Found',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 20,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             const SizedBox(height: 8),
// //             Text(
// //               'No videos available for "${widget.topic}"',
// //               style: TextStyle(
// //                 color: Colors.white.withOpacity(0.7),
// //                 fontSize: 14,
// //               ),
// //               textAlign: TextAlign.center,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // /*
// // Add to pubspec.yaml:
// // dependencies:
// //   flutter:
// //     sdk: flutter
// //   youtube_player_flutter: ^8.1.2
// //   shared_preferences: ^2.2.2
// //
// // Usage:
// // Navigator.push(
// //   context,
// //   MaterialPageRoute(
// //     builder: (context) => VideoPage(topic: 'Flutter Tutorial'),
// //   ),
// // );
// //
// // Saved data structure (stores only headline and link):
// // {
// //   "videoId": "dQw4w9WgXcQ",
// //   "title": "Flutter Tutorial Part 1 - Learn Flutter Step by Step",
// //   "link": "https://youtube.com/watch?v=dQw4w9WgXcQ"
// // }
// // */