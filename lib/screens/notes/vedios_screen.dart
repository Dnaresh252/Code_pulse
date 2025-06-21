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

class _VideoPageState extends State<VideoPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _loading = true;
  List<YoutubeVideo> _videos = [];
  Map<String, bool> _savedStatus = {};
  YoutubePlayerController? _videoController;
  bool _isPlayerVisible = false;
  int _selectedVideoIndex = -1;
  bool _isFullScreen = false;
  bool _isInappropriateContent = false;
  bool _isLandscape = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Orientation change detection
  Timer? _orientationTimer;

  // Same blocked keywords from YouTube service for consistency
  static const List<String> _blockedKeywords = [
    // Adult/Sexual content
    'adult', 'porn', 'sex', 'xxx', 'nude', 'naked', 'explicit', 'nsfw',
    'mature', 'erotic', 'intimate', 'seductive', 'sensual', 'sexual',
    'pornography', 'strip', 'lingerie', 'fetish', 'bdsm', 'escort',
    'hot girls', 'sexy', 'provocative', 'adult content', 'not safe for work',
    '18+', 'adults only', 'mature content', 'sexual content',

    // Violence and harmful content
    'violence', 'violent', 'fight', 'blood', 'kill', 'death', 'murder',
    'weapon', 'gun', 'knife', 'shooting', 'terrorism', 'bomb',

    // Drugs and substance abuse
    'drugs', 'cocaine', 'heroin', 'marijuana', 'weed', 'smoking', 'alcohol',
    'drunk', 'drinking', 'beer', 'wine', 'vodka', 'drug dealer',

    // Gambling and inappropriate activities
    'gambling', 'casino', 'poker', 'betting', 'lottery',

    // Hate speech and inappropriate behavior
    'hate speech', 'racist', 'discrimination', 'bullying', 'harassment',

    // Other inappropriate content
    'suicide', 'self harm', 'depression help', 'cutting', 'anorexia',
    'illegal', 'crime', 'steal', 'robbery', 'fraud', 'kiss', 'kissing'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    _checkContentAndLoadVideos();
    _setInitialOrientation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _orientationTimer?.cancel();
    _resetSystemUI();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleOrientationChange();
    });
  }

  void _setInitialOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _handleOrientationChange() {
    final mediaQuery = MediaQuery.of(context);
    final isCurrentlyLandscape = mediaQuery.orientation == Orientation.landscape;

    if (_isLandscape != isCurrentlyLandscape && _isPlayerVisible) {
      setState(() {
        _isLandscape = isCurrentlyLandscape;
        _isFullScreen = isCurrentlyLandscape;
      });

      _updateSystemUI();
    }
  }

  void _updateSystemUI() {
    if (_isFullScreen || _isLandscape) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _resetSystemUI() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
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

  // Check if the search topic contains inappropriate content
  bool _containsInappropriateContent(String topic) {
    final searchTopic = topic.toLowerCase().trim();

    for (String keyword in _blockedKeywords) {
      if (searchTopic.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  // Check content before loading videos
  Future<void> _checkContentAndLoadVideos() async {
    setState(() => _loading = true);

    // Check if the topic contains inappropriate content
    if (_containsInappropriateContent(widget.topic)) {
      setState(() {
        _loading = false;
        _isInappropriateContent = true;
        _videos = [];
      });
      return;
    }

    // If content is appropriate, load videos normally
    _loadVideos();
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
          _isInappropriateContent = false;
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
        hideControls: false,
      ),
    );

    setState(() {
      _selectedVideoIndex = index;
      _isPlayerVisible = true;
    });
    _slideController.forward();
    HapticFeedback.mediumImpact();
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    HapticFeedback.lightImpact();
  }

  Future<void> _closePlayer() async {
    // Reset orientation and UI first
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    await _slideController.reverse();
    if (mounted) {
      setState(() {
        _isPlayerVisible = false;
        _selectedVideoIndex = -1;
        _isFullScreen = false;
        _isLandscape = false;
        _videoController?.dispose();
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape && _isPlayerVisible) {
      return _buildLandscapePlayer();
    }

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
              if (_isPlayerVisible && !isLandscape) _buildPlayerContent(),
              _buildVideoContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapePlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen video player
            Center(
              child: _buildYouTubePlayer(),
            ),
            // Top controls overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - back button
                  _buildLandscapeButton(
                    icon: Icons.arrow_back,
                    onTap: _closePlayer,
                  ),
                  // Right side - controls
                  Row(
                    children: [
                      if (_selectedVideoIndex >= 0)
                        _buildLandscapeButton(
                          icon: _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          onTap: () => _toggleSaveVideo(_videos[_selectedVideoIndex]),
                        ),
                      const SizedBox(width: 12),
                      _buildLandscapeButton(
                        icon: Icons.fullscreen_exit,
                        onTap: _toggleFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom title overlay
            if (_selectedVideoIndex >= 0)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
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
      ),
    );
  }

  Widget _buildLandscapeButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildYouTubePlayer() {
    if (_videoController == null) return const SizedBox.shrink();

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
      onReady: () {
        debugPrint('Video ready');
      },
      onEnded: (metadata) {
        // Handle video end if needed
      },
      bottomActions: [
        const CurrentPosition(),
        const SizedBox(width: 8),
        const Expanded(child: ProgressBar(isExpanded: true)),
        const SizedBox(width: 8),
        const RemainingDuration(),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
          ),
          onPressed: _toggleFullscreen,
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    return Expanded(
      child: _loading
          ? _buildLoadingState()
          : _isInappropriateContent
          ? _buildInappropriateContentWarning()
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

  // NEW: Build inappropriate content warning
  Widget _buildInappropriateContentWarning() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        return SingleChildScrollView(
          child: Center(
            child: Container(
              margin: EdgeInsets.all(isSmallScreen ? 16 : 20),
              padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '⚠️ Inappropriate Content Detected',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'The search term "${widget.topic}" contains inappropriate content that is not suitable for students.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmallScreen ? 14 : 16,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please search for educational and appropriate content only.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isSmallScreen ? 12 : 14,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Content Guidelines:',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Search for educational topics like math, science, history\n'
                              '• Look for tutorials, lessons, and learning content\n'
                              '• Avoid adult, violent, or inappropriate keywords\n'
                              '• Focus on study-related material',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isSmallScreen ? 12 : 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: Text(
                      'Go Back & Search Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVideoThumbnail(video, isSelected, isSaved, isSmallScreen),
                  const SizedBox(width: 12),
                  Expanded(child: _buildVideoInfo(video, index, isSelected)),
                  _buildSaveButton(video, isSaved),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(YoutubeVideo video, bool isSelected, bool isSaved, bool isSmallScreen) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            video.thumbnailUrl,
            width: isSmallScreen ? 100 : 120,
            height: isSmallScreen ? 60 : 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: isSmallScreen ? 100 : 120,
              height: isSmallScreen ? 60 : 80,
              color: Colors.grey.withOpacity(0.3),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        if (isSaved)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark, size: 12, color: Colors.white),
            ),
          ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: isSmallScreen ? 16 : 20,
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PLAYING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          video.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.touch_app, size: 12, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              'Tap to play',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSaved
                ? [Colors.orange, Colors.orange.shade600]
                : [Colors.green, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: (isSaved ? Colors.orange : Colors.green).withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: Colors.white,
          size: 18,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    if (_selectedVideoIndex < 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
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
          const Icon(Icons.play_circle_filled, color: Color(0xFF00D4AA), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _videos[_selectedVideoIndex].title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildSaveButton(_videos[_selectedVideoIndex],
              _savedStatus[_videos[_selectedVideoIndex].videoId] ?? false),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _toggleFullscreen,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _closePlayer,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learning Videos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topic: ${widget.topic}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_videos.isNotEmpty && !_isPlayerVisible) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.video_library, color: Color(0xFF00D4AA), size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Top ${_videos.length} videos • Tap to play',
                      style: const TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

// Keep the existing SavedVideoItem and VideoStorage classes unchanged
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
  static Future<void> saveVideo(YoutubeVideo video) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final savedVideos = await getSavedVideos();

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
    if (userId == null) return;
    final savedVideos = await getSavedVideos();
    savedVideos.removeWhere((v) => v.videoId == videoId);
    final jsonList = savedVideos.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList('${userId}_saved_videos', jsonList);
  }

  static Future<List<SavedVideoItem>> getSavedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];
    final jsonList = prefs.getStringList('${userId}_saved_videos') ?? [];
    return jsonList.map((json) => SavedVideoItem.fromJson(jsonDecode(json))).toList();
  }

  static Future<bool> isVideoSaved(String videoId) async {
    final savedVideos = await getSavedVideos();
    return savedVideos.any((v) => v.videoId == videoId);
  }

  static Future<int> getSavedVideosCount() async {
    final savedVideos = await getSavedVideos();
    return savedVideos.length;
  }

  static Future<void> clearAllSavedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    await prefs.remove('${userId}_saved_videos');
  }
}

