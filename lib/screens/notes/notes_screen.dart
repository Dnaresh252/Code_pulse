import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Add this line
import '../../models/app_model.dart';

// Add this class to match the one from VideoPage
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

// Combined item class to handle both notes and saved videos
class CombinedItem {
  final String id;
  final String title;
  final String content;
  final ItemType type;
  final DateTime? createdAt;
  final bool isYouTubeVideo;

  CombinedItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.createdAt,
    this.isYouTubeVideo = false,
  });
}

enum ItemType {
  video,
  link,
  youtubeVideo,
}

class VideoStorage {


  static Future<List<SavedVideoItem>> getSavedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return []; // No user logged in, return empty list
    final jsonList = prefs.getStringList('${userId}_saved_videos') ?? [];
    return jsonList.map((json) => SavedVideoItem.fromJson(jsonDecode(json))).toList();
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
}

class NotesPage extends StatefulWidget {
  final List<Note> notes;
  final void Function(int) onDelete;
  final Future<void> Function(int, Note) onUpdate;
  final Future<void> Function(Note) onAdd;

  const NotesPage({
    super.key,
    required this.notes,
    required this.onDelete,
    required this.onUpdate,
    required this.onAdd,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<CombinedItem> _combinedItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllItems();
  }

  Future<void> _loadAllItems() async {
    setState(() => _loading = true);

    try {
      // Get saved YouTube videos
      final savedVideos = await VideoStorage.getSavedVideos();

      // Combine notes and saved videos
      final combinedItems = <CombinedItem>[];

      // Add regular notes
      for (int i = 0; i < widget.notes.length; i++) {
        final note = widget.notes[i];
        combinedItems.add(CombinedItem(
          id: 'note_$i',
          title: note.topic,
          content: note.content,
          type: note.type == NoteType.video ? ItemType.video : ItemType.link,
          createdAt: note.createdAt,
          isYouTubeVideo: false,
        ));
      }

      // Add saved YouTube videos
      for (final video in savedVideos) {
        combinedItems.add(CombinedItem(
          id: 'youtube_${video.videoId}',
          title: video.title,
          content: video.link,
          type: ItemType.youtubeVideo,
          isYouTubeVideo: true,
        ));
      }

      // Sort by creation date if available, otherwise keep original order
      combinedItems.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return 0;
      });

      setState(() {
        _combinedItems = combinedItems;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Error loading items: $e', Colors.red);
    }
  }

  // Helper methods for video/link detection
  bool _isVideoLink(String content) {
    return content.contains('youtube.com') ||
        content.contains('youtu.be') ||
        content.contains('vimeo.com');
  }

  bool _isWebLink(String content) {
    return content.contains('http://') || content.contains('https://');
  }

  String _extractFirstUrl(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().startsWith('http://') || line.trim().startsWith('https://')) {
        return line.trim();
      }
    }
    return content.trim(); // For YouTube videos, the content is the URL itself
  }

  Future<void> _openLink(String content) async {
    final url = _extractFirstUrl(content);
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          HapticFeedback.lightImpact();
        } else {
          _showSnackBar('Could not open link', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Error opening link', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _deleteItem(CombinedItem item) async {
    try {
      if (item.isYouTubeVideo) {
        // Delete YouTube video
        final videoId = item.id.replaceFirst('youtube_', '');
        await VideoStorage.removeVideo(videoId);
        _showSnackBar('YouTube video removed', const Color(0xFF00D4AA));
      } else {
        // Delete regular note
        final noteIndex = int.parse(item.id.replaceFirst('note_', ''));
        widget.onDelete(noteIndex);
        _showSnackBar('Note deleted', const Color(0xFF00D4AA));
      }

      // Reload items
      await _loadAllItems();
    } catch (e) {
      _showSnackBar('Error deleting item', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsCard(),
              Expanded(
                child: _loading
                    ? _buildLoadingState()
                    : _combinedItems.isEmpty
                    ? _buildEmptyState()
                    : _buildItemsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00A8CC), Colors.white],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    'Saved Content',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Videos, links & YouTube saves',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _loadAllItems,
            child: Container(
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
              child: const Icon(
                Icons.refresh,
                color: Color(0xFF00D4AA),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final videoCount = _combinedItems.where((item) => item.type == ItemType.video).length;
    final linkCount = _combinedItems.where((item) => item.type == ItemType.link).length;
    final youtubeCount = _combinedItems.where((item) => item.type == ItemType.youtubeVideo).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Saved',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_combinedItems.length} ${_combinedItems.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_combinedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (videoCount > 0) ...[
                  _buildTypeChip('Videos', videoCount, Colors.red, Icons.play_circle_filled),
                  const SizedBox(width: 8),
                ],
                if (linkCount > 0) ...[
                  _buildTypeChip('Links', linkCount, Colors.blue, Icons.link_rounded),
                  const SizedBox(width: 8),
                ],
                if (youtubeCount > 0) ...[
                  _buildTypeChip('YouTube', youtubeCount, Colors.orange, Icons.video_library),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Content Saved',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved videos, links, and YouTube videos will appear here.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _combinedItems.length,
      itemBuilder: (context, index) {
        return _buildItemCard(_combinedItems[index]);
      },
    );
  }

  Widget _buildItemCard(CombinedItem item) {
    final url = _extractFirstUrl(item.content);
    Color primaryColor;
    IconData primaryIcon;
    IconData actionIcon;
    String typeLabel;
    String actionText;

    switch (item.type) {
      case ItemType.video:
        primaryColor = Colors.red;
        primaryIcon = Icons.play_circle_filled;
        actionIcon = Icons.play_arrow;
        typeLabel = 'VIDEO';
        actionText = 'Tap to play video';
        break;
      case ItemType.link:
        primaryColor = Colors.blue;
        primaryIcon = Icons.link_rounded;
        actionIcon = Icons.open_in_new;
        typeLabel = 'LINK';
        actionText = 'Tap to open link';
        break;
      case ItemType.youtubeVideo:
        primaryColor = Colors.orange;
        primaryIcon = Icons.video_library;
        actionIcon = Icons.play_arrow;
        typeLabel = 'YOUTUBE';
        actionText = 'Tap to watch on YouTube';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLink(item.content),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        primaryIcon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        actionIcon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteItem(item),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.2),
                              Colors.red.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // URL Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.type == ItemType.youtubeVideo ? Icons.videocam : primaryIcon,
                        color: primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          url,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      actionIcon,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      actionText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}