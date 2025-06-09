import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/youtube_video.dart';
import '../../services/youtube_service.dart';

class VideoPage extends StatefulWidget {
  final String topic;
  const VideoPage({super.key, required this.topic});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  bool _loading = true;
  List<YoutubeVideo> _videos = [];
  YoutubePlayerController? _videoController; // nullable
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await YoutubeService.fetchVideos(widget.topic);
      if (videos.isNotEmpty) {
        _videoController = YoutubePlayerController(
          initialVideoId: videos.first.videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
          ),
        );
      }
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load videos: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  void _playVideo(String videoId) {
    if (_videoController != null) {
      _videoController!.load(videoId);
      _videoController!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.teal[700],
        colorScheme: ColorScheme.light(
          primary: Colors.teal[700]!,
          secondary: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.teal[900],
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.teal[700],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _isFullScreen
            ? null
            : AppBar(
          title: Text('Videos: ${widget.topic}'),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _videos.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No videos found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: _loadVideos,
                child: const Text('Try Again'),
              ),
            ],
          ),
        )
            : Column(
          children: [
            if (!_isFullScreen)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select a video to play',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            Expanded(
              child: _isFullScreen
                  ? _buildVideoPlayer()
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return _buildVideoCard(video);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null) {
      return Center(child: Text('Video player not initialized.'));
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _videoController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.teal[700],
        progressColors: ProgressBarColors(
          playedColor: Colors.teal[700]!,
          handleColor: Colors.tealAccent,
        ),
        onReady: () {},
        onEnded: (data) {
          setState(() => _isFullScreen = false);
        },
      ),
      builder: (context, player) {
        return GestureDetector(
          onTap: () {
            setState(() => _isFullScreen = !_isFullScreen);
          },
          child: player,
        );
      },
    );
  }

  Widget _buildVideoCard(YoutubeVideo video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _playVideo(video.videoId);
          setState(() => _isFullScreen = true);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                            color: Colors.teal[700],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                video.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
