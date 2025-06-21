import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_model.dart';
import '../../models/google_search_result.dart';
import '../../services/google_search_serivce.dart';
import 'notes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vedios_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String _query = '';
  List<GoogleSearchResult> _googleLinks = [];
  List<Note> _notes = [];
  int _savedNotesCount = 0;
  Set<String> _savedLinks = {};

  // Content detection
  bool _isInappropriateContent = false;
  String _inappropriateKeywordFound = '';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _codeController;
  late AnimationController _bounceController;
  late AnimationController _saveController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _codeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _saveAnimation;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // Content filtering keywords
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
    'illegal', 'crime', 'steal', 'robbery', 'fraud'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  @override
  void dispose() {
    // Stop all animations before disposing
    _fadeController.stop();
    _pulseController.stop();
    _codeController.stop();
    _bounceController.stop();
    _saveController.stop();

    // Dispose controllers
    _fadeController.dispose();
    _pulseController.dispose();
    _codeController.dispose();
    _bounceController.dispose();
    _saveController.dispose();

    // Dispose text controller
    _controller.dispose();

    super.dispose();
  }

  void _initializeControllers() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _codeController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _saveController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _codeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _codeController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _saveAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _saveController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    if (mounted) {
      _fadeController.forward();
      _pulseController.repeat(reverse: true);
      _codeController.repeat();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadSavedNotes(),
        _loadSavedLinks(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> _loadSavedNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || !mounted) return;

      final notesJson = prefs.getStringList('${userId}_saved_notes') ?? [];

      if (mounted) {
        setState(() {
          _notes = notesJson.map((noteString) {
            final parts = noteString.split('|||');
            if (parts.length >= 2) {
              return Note(topic: parts[0], content: parts[1]);
            }
            return Note(topic: 'Untitled', content: noteString);
          }).toList();
          _savedNotesCount = _notes.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved notes: $e');
    }
  }

  Future<void> _loadSavedLinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || !mounted) return;

      final notesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
      final savedLinks = <String>{};

      for (final noteString in notesJson) {
        final parts = noteString.split('|||');
        if (parts.length >= 2) {
          final urlRegExp = RegExp(r'https?://[^\s]+');
          final matches = urlRegExp.allMatches(parts[1]);
          for (final match in matches) {
            final url = match.group(0);
            if (url != null) {
              savedLinks.add(url);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _savedLinks = savedLinks;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved links: $e');
    }
  }

  bool _containsInappropriateContent(String query) {
    final searchQuery = query.toLowerCase().trim();

    for (String keyword in _blockedKeywords) {
      if (searchQuery.contains(keyword)) {
        _inappropriateKeywordFound = keyword;
        return true;
      }
    }
    return false;
  }

  Future<void> _saveNoteToStorage(Note note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || !mounted) return;

      _notes.add(note);

      final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
      await prefs.setStringList('${userId}_saved_notes', notesJson);

      final urlRegExp = RegExp(r'https?://[^\s]+');
      final matches = urlRegExp.allMatches(note.content);
      final newLinks = matches.map((m) => m.group(0)).whereType<String>().toList();

      if (mounted) {
        setState(() {
          _savedNotesCount = _notes.length;
          _savedLinks.addAll(newLinks);
        });

        _bounceController.reset();
        _bounceController.forward();
        _saveController.forward().then((_) {
          if (mounted) {
            _saveController.reverse();
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save note');
      }
    }
  }

  bool _isLinkSaved(String url) {
    return _savedLinks.contains(url);
  }

  Future<void> _toggleSaveLink(GoogleSearchResult link) async {
    try {
      HapticFeedback.mediumImpact();

      if (_isLinkSaved(link.link)) {
        // Remove link from notes
        final notesToRemove = <Note>[];
        for (final note in _notes) {
          if (note.content.contains(link.link)) {
            notesToRemove.add(note);
          }
        }

        if (notesToRemove.isNotEmpty && mounted) {
          setState(() {
            _notes.removeWhere((note) => notesToRemove.contains(note));
            _savedLinks.remove(link.link);
            _savedNotesCount = _notes.length;
          });

          final prefs = await SharedPreferences.getInstance();
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
            await prefs.setStringList('${userId}_saved_notes', notesJson);
          }

          if (mounted) {
            _showSuccessSnackBar('Link removed from notes');
          }
        }
      } else {
        // Add link to notes
        final note = Note(
          topic: link.title,
          content: '${link.link}\n\nSaved from search: $_query',
        );

        await _saveNoteToStorage(note);
        if (mounted) {
          _showSuccessSnackBar('Link saved to notes!');
        }
      }
    } catch (e) {
      debugPrint('Error toggling save link: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save/remove link');
      }
    }
  }

  // Responsive helper methods
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  bool _isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (_isMobile(context)) {
      return baseSize * (width / 375).clamp(0.8, 1.2);
    } else if (_isTablet(context)) {
      return baseSize * 1.1;
    }
    return baseSize * 1.2;
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    if (_isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (_isTablet(context)) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(32);
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    if (_isMobile(context)) {
      return baseSpacing;
    } else if (_isTablet(context)) {
      return baseSpacing * 1.2;
    }
    return baseSpacing * 1.4;
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty || !mounted) return;

    try {
      HapticFeedback.lightImpact();

      setState(() {
        _loading = true;
        _query = query;
        _googleLinks = [];
        _isInappropriateContent = false;
        _inappropriateKeywordFound = '';
      });

      // Check for inappropriate content before API call
      if (_containsInappropriateContent(query)) {
        if (mounted) {
          setState(() {
            _loading = false;
            _isInappropriateContent = true;
            _googleLinks = [];
          });
        }
        return;
      }

      // Proceed with search if content is appropriate
      final links = await GoogleSearchService.fetchGoogleLinks(query);

      if (mounted) {
        setState(() {
          _googleLinks = links;
          _isInappropriateContent = false;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');

      if (mounted) {
        setState(() {
          _googleLinks = [];
          _loading = false;
        });

        if (e.toString().contains('Inappropriate search content detected')) {
          setState(() {
            _isInappropriateContent = true;
          });
        } else {
          _showErrorSnackBar('Failed to fetch search results. Please try again.');
        }
      }
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showErrorSnackBar('Could not open the link');
        }
      }
    } catch (e) {
      debugPrint('Error opening link: $e');
      if (mounted) {
        _showErrorSnackBar('Error opening link');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF00D4AA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: _getResponsivePadding(context),
                    child: Column(
                      children: [
                        _buildSearchSection(),
                        SizedBox(height: _getResponsiveSpacing(context, 24)),
                        if (_loading) _buildLoadingIndicator(),
                        if (_query.isNotEmpty && !_loading) _buildResultsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: _getResponsivePadding(context),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: EdgeInsets.all(_isMobile(context) ? 10 : 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: const Color(0xFF00D4AA),
                size: _isMobile(context) ? 18 : 20,
              ),
            ),
          ),
          SizedBox(width: _isMobile(context) ? 12 : 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _codeController.isCompleted ? _codeAnimation : _fadeController,
                  builder: (context, child) {
                    final animValue = _codeController.isCompleted ? _codeAnimation.value : 0.5;
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Color.lerp(const Color(0xFF00D4AA), const Color(0xFF00A8CC), animValue) ?? const Color(0xFF00D4AA),
                          Colors.white,
                          Color.lerp(const Color(0xFF00A8CC), const Color(0xFF00D4AA), animValue) ?? const Color(0xFF00A8CC),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        '<SafeSearch/>',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(context, 20),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: _isMobile(context) ? 3 : 4),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isMobile(context) ? 6 : 8,
                    vertical: _isMobile(context) ? 1 : 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.3),
                        Colors.green.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Protected Hub',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: _getResponsiveFontSize(context, 10),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () async {
              try {
                HapticFeedback.mediumImpact();
                if (mounted) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotesPage(
                        notes: _notes,
                        onAdd: (note) => _saveNoteToStorage(note),
                        onUpdate: (index, note) async {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final userId = FirebaseAuth.instance.currentUser?.uid;
                            if (userId == null || !mounted) return;

                            _notes[index] = note as Note;
                            final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
                            await prefs.setStringList('${userId}_saved_notes', notesJson);

                            if (mounted) {
                              setState(() {});
                            }
                          } catch (e) {
                            debugPrint('Error updating note: $e');
                          }
                        },
                        onDelete: (index) async {
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final userId = FirebaseAuth.instance.currentUser?.uid;
                            if (userId == null || !mounted) return;

                            _notes.removeAt(index);
                            final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
                            await prefs.setStringList('${userId}_saved_notes', notesJson);

                            if (mounted) {
                              setState(() {
                                _savedNotesCount = _notes.length;
                              });
                            }
                          } catch (e) {
                            debugPrint('Error deleting note: $e');
                          }
                        },
                      ),
                    ),
                  );

                  if (mounted) {
                    await _loadSavedNotes();
                  }
                }
              } catch (e) {
                debugPrint('Error navigating to notes: $e');
              }
            },
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_bounceAnimation.value * 0.08),
                  child: Container(
                    padding: EdgeInsets.all(_isMobile(context) ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.library_books_rounded,
                      color: Colors.white,
                      size: _isMobile(context) ? 18 : 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(_isMobile(context) ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(_isMobile(context) ? 20 : 24),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(_isMobile(context) ? 10 : 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: _isMobile(context) ? 20 : 24,
                      ),
                    ),
                    SizedBox(width: _isMobile(context) ? 12 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safe Search Engine',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: _isMobile(context) ? 2 : 4),
                          Text(
                            'Find educational resources safely',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: _getResponsiveFontSize(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getResponsiveSpacing(context, 16)),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(context, 14),
                    ),
                    decoration: InputDecoration(
                      hintText: _isMobile(context)
                          ? 'Search safely...'
                          : 'Search for educational content safely...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: _getResponsiveFontSize(context, 14),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _isMobile(context) ? 16 : 20,
                        vertical: _isMobile(context) ? 14 : 16,
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D4AA).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: _isMobile(context) ? 20 : 22,
                          ),
                          onPressed: _search,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.all(_isMobile(context) ? 32 : 40),
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
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _isMobile(context) ? 50 : 60,
                height: _isMobile(context) ? 50 : 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: _isMobile(context) ? 30 : 40,
                height: _isMobile(context) ? 30 : 40,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSpacing(context, 16)),
          Text(
            'Searching safely for "$_query"...',
            style: TextStyle(
              color: Colors.white,
              fontSize: _getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 6)),
          Text(
            'Finding safe educational resources',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: _getResponsiveFontSize(context, 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInappropriateContentWarning() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isMobile(context) ? 16 : 20,
        vertical: _isMobile(context) ? 16 : 20,
      ),
      padding: EdgeInsets.all(_isMobile(context) ? 20 : 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.15),
            Colors.orange.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.red.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.warning_rounded,
              size: _isMobile(context) ? 50 : 60,
              color: Colors.red,
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 20)),

          Text(
            '⚠️ Inappropriate Content Detected',
            style: TextStyle(
              color: Colors.white,
              fontSize: _getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _getResponsiveSpacing(context, 16)),

          Container(
            padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'The search term "$_query" contains inappropriate content that is not suitable for students.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: _getResponsiveFontSize(context, 14),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: _getResponsiveSpacing(context, 12)),
                if (_inappropriateKeywordFound.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isMobile(context) ? 8 : 12,
                      vertical: _isMobile(context) ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      'Blocked keyword: "$_inappropriateKeywordFound"',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: _getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                SizedBox(height: _getResponsiveSpacing(context, 12)),
                Text(
                  'Please search for educational and appropriate content only.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: _getResponsiveFontSize(context, 12),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 20)),

          Container(
            padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: _isMobile(context) ? 18 : 20,
                    ),
                    SizedBox(width: _isMobile(context) ? 8 : 10),
                    Text(
                      'Search Guidelines:',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: _getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getResponsiveSpacing(context, 12)),
                Text(
                  '• Search for educational topics like programming, science, math\n'
                      '• Look for tutorials, documentation, and learning resources\n'
                      '• Avoid adult, violent, or inappropriate keywords\n'
                      '• Focus on study and research-related material\n'
                      '• Use professional and academic search terms',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: _getResponsiveFontSize(context, 12),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 24)),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _controller.clear();
                    if (mounted) {
                      setState(() {
                        _query = '';
                        _isInappropriateContent = false;
                        _inappropriateKeywordFound = '';
                        _googleLinks = [];
                      });
                    }
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: _isMobile(context) ? 16 : 18,
                  ),
                  label: Text(
                    'Clear & Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    padding: EdgeInsets.symmetric(
                      horizontal: _isMobile(context) ? 16 : 20,
                      vertical: _isMobile(context) ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: _isMobile(context) ? 12 : 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: _isMobile(context) ? 16 : 18,
                  ),
                  label: Text(
                    'Go Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isMobile(context) ? 16 : 20,
                      vertical: _isMobile(context) ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isInappropriateContent) {
      return _buildInappropriateContentWarning();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(_isMobile(context) ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: _isMobile(context) ? 16 : 18,
                ),
              ),
              SizedBox(width: _isMobile(context) ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Safe Search Results',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: _isMobile(context) ? 6 : 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isMobile(context) ? 4 : 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'FILTERED',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: _getResponsiveFontSize(context, 8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _isMobile(context) ? 2 : 4),
                    Text(
                      'Found ${_googleLinks.length} safe results for "$_query"',
                      style: TextStyle(
                        color: const Color(0xFF00D4AA),
                        fontSize: _getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _getResponsiveSpacing(context, 16)),

        if (_googleLinks.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: [
              _buildLinksList(),
              SizedBox(height: _getResponsiveSpacing(context, 20)),
              _buildVideosButton(),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(_isMobile(context) ? 32 : 40),
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
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(_isMobile(context) ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.3),
                  Colors.orange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: _isMobile(context) ? 40 : 48,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 16)),
          Text(
            'No Safe Results Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: _getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 6)),
          Text(
            'Try different keywords or check spelling',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: _getResponsiveFontSize(context, 12),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLinksList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _googleLinks.length,
      separatorBuilder: (context, index) => SizedBox(height: _getResponsiveSpacing(context, 12)),
      itemBuilder: (context, index) {
        final link = _googleLinks[index];
        final isSaved = _isLinkSaved(link.link);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSaved
                  ? const Color(0xFF00D4AA).withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openLink(link.link),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(_isMobile(context) ? 6 : 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSaved
                                  ? [Colors.orange, Colors.deepOrange]
                                  : [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: _isMobile(context) ? 14 : 16,
                          ),
                        ),
                        SizedBox(width: _isMobile(context) ? 10 : 12),

                        Expanded(
                          child: Text(
                            link.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: _getResponsiveFontSize(context, 14),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: _isMobile(context) ? 8 : 12),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isMobile(context) ? 4 : 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'SAFE',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: _getResponsiveFontSize(context, 8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: _isMobile(context) ? 8 : 12),

                        AnimatedBuilder(
                          animation: _saveAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _saveAnimation.value,
                              child: Container(
                                padding: EdgeInsets.all(_isMobile(context) ? 8 : 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSaved
                                        ? [Colors.orange, Colors.deepOrange]
                                        : [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSaved
                                          ? Colors.orange.withOpacity(0.3)
                                          : const Color(0xFF00D4AA).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => _toggleSaveLink(link),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Icon(
                                    isSaved
                                        ? Icons.bookmark_remove_rounded
                                        : Icons.bookmark_add_rounded,
                                    color: Colors.white,
                                    size: _isMobile(context) ? 16 : 18,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 10)),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isMobile(context) ? 10 : 12,
                        vertical: _isMobile(context) ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSaved
                              ? [Colors.orange.withOpacity(0.3), Colors.deepOrange.withOpacity(0.2)]
                              : [const Color(0xFF00D4AA).withOpacity(0.2), const Color(0xFF00A8CC).withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSaved
                              ? Colors.orange.withOpacity(0.5)
                              : const Color(0xFF00D4AA).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        link.link,
                        style: TextStyle(
                          color: isSaved ? Colors.orange : const Color(0xFF00D4AA),
                          fontSize: _getResponsiveFontSize(context, 10),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: _getResponsiveSpacing(context, 8)),

                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: _isMobile(context) ? 12 : 14,
                          color: Colors.green,
                        ),
                        SizedBox(width: _isMobile(context) ? 4 : 6),
                        Text(
                          'Safe content • Tap to open',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: _getResponsiveFontSize(context, 10),
                          ),
                        ),
                        const Spacer(),
                        if (isSaved) ...[
                          Icon(
                            Icons.check_circle_rounded,
                            size: _isMobile(context) ? 12 : 14,
                            color: Colors.orange,
                          ),
                          SizedBox(width: _isMobile(context) ? 4 : 6),
                          Text(
                            'Saved in notes',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: _getResponsiveFontSize(context, 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosButton() {
    return Container(
      width: double.infinity,
      height: _isMobile(context) ? 48 : 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.deepPurple],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            try {
              HapticFeedback.lightImpact();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPage(topic: _query),
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error navigating to videos: $e');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: _isMobile(context) ? 20 : 24,
                ),
                SizedBox(width: _isMobile(context) ? 8 : 12),
                Text(
                  "View Safe Related Videos",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../models/app_model.dart';
// import '../../models/google_search_result.dart';
// import '../../services/google_search_serivce.dart';
// import 'notes_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'vedios_screen.dart';
//
// class SearchPage extends StatefulWidget {
//   const SearchPage({super.key});
//
//   @override
//   State<SearchPage> createState() => _SearchPageState();
// }
//
// class _SearchPageState extends State<SearchPage>
//     with TickerProviderStateMixin {
//   final TextEditingController _controller = TextEditingController();
//   bool _loading = false;
//   String _query = '';
//   List<GoogleSearchResult> _googleLinks = [];
//   List<Note> _notes = [];
//   int _savedNotesCount = 0;
//   Set<String> _savedLinks = {};
//
//   // NEW: Inappropriate content detection
//   bool _isInappropriateContent = false;
//   String _inappropriateKeywordFound = '';
//
//   late AnimationController _fadeController;
//   late AnimationController _pulseController;
//   late AnimationController _codeController;
//   late AnimationController _bounceController;
//   late AnimationController _saveController;
//
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _pulseAnimation;
//   late Animation<double> _codeAnimation;
//   late Animation<double> _bounceAnimation;
//   late Animation<double> _saveAnimation;
//
//   // Responsive breakpoints
//   static const double mobileBreakpoint = 600;
//   static const double tabletBreakpoint = 900;
//
//   // SAME BLOCKED KEYWORDS FROM GOOGLE SERVICE
//   static const List<String> _blockedKeywords = [
//     // Adult/Sexual content
//     'adult', 'porn', 'sex', 'xxx', 'nude', 'naked', 'explicit', 'nsfw',
//     'mature', 'erotic', 'intimate', 'seductive', 'sensual', 'sexual',
//     'pornography', 'strip', 'lingerie', 'fetish', 'bdsm', 'escort',
//     'hot girls', 'sexy', 'provocative', 'adult content', 'not safe for work',
//     '18+', 'adults only', 'mature content', 'sexual content',
//
//     // Violence and harmful content
//     'violence', 'violent', 'fight', 'blood', 'kill', 'death', 'murder',
//     'weapon', 'gun', 'knife', 'shooting', 'terrorism', 'bomb',
//
//     // Drugs and substance abuse
//     'drugs', 'cocaine', 'heroin', 'marijuana', 'weed', 'smoking', 'alcohol',
//     'drunk', 'drinking', 'beer', 'wine', 'vodka', 'drug dealer',
//
//     // Gambling and inappropriate activities
//     'gambling', 'casino', 'poker', 'betting', 'lottery',
//
//     // Hate speech and inappropriate behavior
//     'hate speech', 'racist', 'discrimination', 'bullying', 'harassment',
//
//     // Other inappropriate content
//     'suicide', 'self harm', 'depression help', 'cutting', 'anorexia',
//     'illegal', 'crime', 'steal', 'robbery', 'fraud'
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//     _loadSavedNotes();
//     _loadSavedLinks();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeAnimations();
//       _startAnimations();
//     });
//   }
//
//   // NEW: Content detection method
//   bool _containsInappropriateContent(String query) {
//     final searchQuery = query.toLowerCase().trim();
//
//     for (String keyword in _blockedKeywords) {
//       if (searchQuery.contains(keyword)) {
//         _inappropriateKeywordFound = keyword;
//         return true;
//       }
//     }
//     return false;
//   }
//
//   void _initializeControllers() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     );
//
//     _codeController = AnimationController(
//       duration: const Duration(milliseconds: 3000),
//       vsync: this,
//     );
//
//     _bounceController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//
//     _saveController = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );
//   }
//
//   void _initializeAnimations() {
//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeInOut,
//     );
//
//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.02,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
//
//     _codeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _codeController,
//       curve: Curves.easeInOut,
//     ));
//
//     _bounceAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _bounceController,
//       curve: Curves.elasticOut,
//     ));
//
//     _saveAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.2,
//     ).animate(CurvedAnimation(
//       parent: _saveController,
//       curve: Curves.elasticOut,
//     ));
//   }
//
//   Future<void> _loadSavedNotes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     final notesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
//
//     setState(() {
//       _notes = notesJson.map((noteString) {
//         final parts = noteString.split('|||');
//         if (parts.length >= 2) {
//           return Note(topic: parts[0], content: parts[1]);
//         }
//         return Note(topic: 'Untitled', content: noteString);
//       }).toList();
//       _savedNotesCount = _notes.length;
//     });
//   }
//
//   Future<void> _loadSavedLinks() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     final notesJson = prefs.getStringList('${userId}_saved_notes') ?? [];
//     final savedLinks = <String>{};
//     for (final noteString in notesJson) {
//       final parts = noteString.split('|||');
//       if (parts.length >= 2) {
//         final urlRegExp = RegExp(r'https?://[^\s]+');
//         final matches = urlRegExp.allMatches(parts[1]);
//         for (final match in matches) {
//           savedLinks.add(match.group(0)!);
//         }
//       }
//     }
//
//     setState(() {
//       _savedLinks = savedLinks;
//     });
//   }
//
//   Future<void> _saveNoteToStorage(Note note) async {
//     final prefs = await SharedPreferences.getInstance();
//     _notes.add(note);
//
//     final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;
//     await prefs.setStringList('${userId}_saved_notes', notesJson);
//
//     final urlRegExp = RegExp(r'https?://[^\s]+');
//     final matches = urlRegExp.allMatches(note.content);
//     final newLinks = matches.map((m) => m.group(0)!).toList();
//
//     setState(() {
//       _savedNotesCount = _notes.length;
//       _savedLinks.addAll(newLinks);
//     });
//
//     _bounceController.reset();
//     _bounceController.forward();
//     _saveController.forward().then((_) => _saveController.reverse());
//   }
//
//   bool _isLinkSaved(String url) {
//     return _savedLinks.contains(url);
//   }
//
//   Future<void> _toggleSaveLink(GoogleSearchResult link) async {
//     HapticFeedback.mediumImpact();
//
//     if (_isLinkSaved(link.link)) {
//       final notesToRemove = <Note>[];
//       for (final note in _notes) {
//         if (note.content.contains(link.link)) {
//           notesToRemove.add(note);
//         }
//       }
//
//       if (notesToRemove.isNotEmpty) {
//         setState(() {
//           _notes.removeWhere((note) => notesToRemove.contains(note));
//           _savedLinks.remove(link.link);
//           _savedNotesCount = _notes.length;
//         });
//
//         final prefs = await SharedPreferences.getInstance();
//         final userId = FirebaseAuth.instance.currentUser?.uid;
//         if (userId == null) return;
//         final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
//         await prefs.setStringList('${userId}_saved_notes', notesJson);
//
//         _showSuccessSnackBar('Link removed from notes');
//       }
//     } else {
//       final note = Note(
//         topic: link.title,
//         content: '${link.link}\n\nSaved from search: $_query',
//       );
//
//       await _saveNoteToStorage(note);
//       _showSuccessSnackBar('Link saved to notes!');
//     }
//   }
//
//   // Responsive helper methods
//   bool _isMobile(BuildContext context) {
//     return MediaQuery.of(context).size.width < mobileBreakpoint;
//   }
//
//   bool _isTablet(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     return width >= mobileBreakpoint && width < tabletBreakpoint;
//   }
//
//   double _getResponsiveFontSize(BuildContext context, double baseSize) {
//     final width = MediaQuery.of(context).size.width;
//     if (_isMobile(context)) {
//       return baseSize * (width / 375).clamp(0.8, 1.2);
//     } else if (_isTablet(context)) {
//       return baseSize * 1.1;
//     }
//     return baseSize * 1.2;
//   }
//
//   EdgeInsets _getResponsivePadding(BuildContext context) {
//     if (_isMobile(context)) {
//       return const EdgeInsets.all(16);
//     } else if (_isTablet(context)) {
//       return const EdgeInsets.all(24);
//     }
//     return const EdgeInsets.all(32);
//   }
//
//   double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
//     if (_isMobile(context)) {
//       return baseSpacing;
//     } else if (_isTablet(context)) {
//       return baseSpacing * 1.2;
//     }
//     return baseSpacing * 1.4;
//   }
//
//   void _startAnimations() {
//     _fadeController.forward();
//     _pulseController.repeat(reverse: true);
//     _codeController.repeat();
//   }
//
//   // UPDATED: Search method with content check
//   Future<void> _search() async {
//     final query = _controller.text.trim();
//     if (query.isEmpty) return;
//
//     HapticFeedback.lightImpact();
//
//     setState(() {
//       _loading = true;
//       _query = query;
//       _googleLinks = [];
//       _isInappropriateContent = false;
//       _inappropriateKeywordFound = '';
//     });
//
//     // CHECK FOR INAPPROPRIATE CONTENT BEFORE API CALL
//     if (_containsInappropriateContent(query)) {
//       setState(() {
//         _loading = false;
//         _isInappropriateContent = true;
//         _googleLinks = [];
//       });
//       return;
//     }
//
//     // IF CONTENT IS APPROPRIATE, PROCEED WITH SEARCH
//     try {
//       final links = await GoogleSearchService.fetchGoogleLinks(query);
//       setState(() {
//         _googleLinks = links;
//         _isInappropriateContent = false;
//       });
//     } catch (e) {
//       setState(() {
//         _googleLinks = [];
//         _isInappropriateContent = false;
//       });
//
//       if (e.toString().contains('Inappropriate search content detected')) {
//         setState(() {
//           _isInappropriateContent = true;
//         });
//       } else {
//         _showErrorSnackBar('Failed to fetch search results. Please try again.');
//       }
//     } finally {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }
//
//   Future<void> _openLink(String url) async {
//     try {
//       final uri = Uri.parse(url);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } else {
//         _showErrorSnackBar('Could not open the link');
//       }
//     } catch (e) {
//       _showErrorSnackBar('Error opening link: ${e.toString()}');
//     }
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.red.shade600,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white, size: 20),
//             const SizedBox(width: 8),
//             Text(message),
//           ],
//         ),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: const Color(0xFF00D4AA),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _pulseController.dispose();
//     _codeController.dispose();
//     _bounceController.dispose();
//     _saveController.dispose();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
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
//             stops: [0.0, 0.5, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: Column(
//               children: [
//                 _buildHeader(),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: _getResponsivePadding(context),
//                     child: Column(
//                       children: [
//                         _buildSearchSection(),
//                         SizedBox(height: _getResponsiveSpacing(context, 24)),
//                         if (_loading) _buildLoadingIndicator(),
//                         if (_query.isNotEmpty && !_loading) _buildResultsSection(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: _getResponsivePadding(context),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () {
//               HapticFeedback.lightImpact();
//               Navigator.pop(context);
//             },
//             child: Container(
//               padding: EdgeInsets.all(_isMobile(context) ? 10 : 12),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.white.withOpacity(0.15),
//                     Colors.white.withOpacity(0.08),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.25),
//                   width: 1,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 Icons.arrow_back_ios,
//                 color: const Color(0xFF00D4AA),
//                 size: _isMobile(context) ? 18 : 20,
//               ),
//             ),
//           ),
//           SizedBox(width: _isMobile(context) ? 12 : 16),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 AnimatedBuilder(
//                   animation: _codeController.isCompleted ? _codeAnimation : _fadeController,
//                   builder: (context, child) {
//                     final animValue = _codeController.isCompleted ? _codeAnimation.value : 0.5;
//                     return ShaderMask(
//                       shaderCallback: (bounds) => LinearGradient(
//                         colors: [
//                           Color.lerp(const Color(0xFF00D4AA), const Color(0xFF00A8CC), animValue) ?? const Color(0xFF00D4AA),
//                           Colors.white,
//                           Color.lerp(const Color(0xFF00A8CC), const Color(0xFF00D4AA), animValue) ?? const Color(0xFF00A8CC),
//                         ],
//                         stops: const [0.0, 0.5, 1.0],
//                       ).createShader(bounds),
//                       child: Text(
//                         '<SafeSearch/>',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: _getResponsiveFontSize(context, 20),
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.5,
//                           fontFamily: 'monospace',
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//                 SizedBox(height: _isMobile(context) ? 3 : 4),
//
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: _isMobile(context) ? 6 : 8,
//                     vertical: _isMobile(context) ? 1 : 2,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.green.withOpacity(0.3),
//                         Colors.green.withOpacity(0.1),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(
//                       color: Colors.green.withOpacity(0.5),
//                       width: 1,
//                     ),
//                   ),
//                   child: Text(
//                     'Protected Hub',
//                     style: TextStyle(
//                       color: Colors.green,
//                       fontSize: _getResponsiveFontSize(context, 10),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           GestureDetector(
//             onTap: () {
//               HapticFeedback.mediumImpact();
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => NotesPage(
//                     notes: _notes,
//                     onAdd: (note) => _saveNoteToStorage(note),
//                     onUpdate: (index, note) async {
//                       final prefs = await SharedPreferences.getInstance();
//                       final userId = FirebaseAuth.instance.currentUser?.uid;
//                       if (userId == null) return;
//                       _notes[index] = note as Note;
//                       final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
//                       await prefs.setStringList('${userId}_saved_notes', notesJson);
//                       setState(() {});
//                     },
//                     onDelete: (index) async {
//                       final prefs = await SharedPreferences.getInstance();
//                       final userId = FirebaseAuth.instance.currentUser?.uid;
//                       if (userId == null) return;
//                       _notes.removeAt(index);
//                       final notesJson = _notes.map((n) => '${n.topic}|||${n.content}').toList();
//                       await prefs.setStringList('${userId}_saved_notes', notesJson);
//                       setState(() {
//                         _savedNotesCount = _notes.length;
//                       });
//                     },
//                   ),
//                 ),
//               ).then((_) => _loadSavedNotes());
//             },
//             child: AnimatedBuilder(
//               animation: _bounceAnimation,
//               builder: (context, child) {
//                 return Transform.scale(
//                   scale: 1.0 + (_bounceAnimation.value * 0.08),
//                   child: Stack(
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(_isMobile(context) ? 10 : 12),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                           ),
//                           borderRadius: BorderRadius.circular(14),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF00D4AA).withOpacity(0.4),
//                               blurRadius: 12,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Icon(
//                           Icons.library_books_rounded,
//                           color: Colors.white,
//                           size: _isMobile(context) ? 18 : 20,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchSection() {
//     return AnimatedBuilder(
//       animation: _pulseAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _pulseAnimation.value,
//           child: Container(
//             padding: EdgeInsets.all(_isMobile(context) ? 20 : 24),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.white.withOpacity(0.15),
//                   Colors.white.withOpacity(0.08),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(_isMobile(context) ? 20 : 24),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.25),
//                 width: 1,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   blurRadius: 20,
//                   offset: const Offset(0, 8),
//                 ),
//                 BoxShadow(
//                   color: const Color(0xFF00D4AA).withOpacity(0.1),
//                   blurRadius: 15,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: EdgeInsets.all(_isMobile(context) ? 10 : 12),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                         ),
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFF00D4AA).withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Icon(
//                         Icons.verified_user,
//                         color: Colors.white,
//                         size: _isMobile(context) ? 20 : 24,
//                       ),
//                     ),
//                     SizedBox(width: _isMobile(context) ? 12 : 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Safe Search Engine',
//                             style: TextStyle(
//                               fontSize: _getResponsiveFontSize(context, 16),
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           SizedBox(height: _isMobile(context) ? 2 : 4),
//                           Text(
//                             'Find educational resources safely',
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.7),
//                               fontSize: _getResponsiveFontSize(context, 12),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: _getResponsiveSpacing(context, 16)),
//
//                 Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.white.withOpacity(0.12),
//                         Colors.white.withOpacity(0.06),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.2),
//                       width: 1,
//                     ),
//                   ),
//                   child: TextField(
//                     controller: _controller,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: _getResponsiveFontSize(context, 14),
//                     ),
//                     decoration: InputDecoration(
//                       hintText: _isMobile(context)
//                           ? 'Search safely...'
//                           : 'Search for educational content safely...',
//                       hintStyle: TextStyle(
//                         color: Colors.white.withOpacity(0.6),
//                         fontSize: _getResponsiveFontSize(context, 14),
//                       ),
//                       border: InputBorder.none,
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: _isMobile(context) ? 16 : 20,
//                         vertical: _isMobile(context) ? 14 : 16,
//                       ),
//                       suffixIcon: Container(
//                         margin: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF00D4AA).withOpacity(0.3),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: IconButton(
//                           icon: Icon(
//                             Icons.search_rounded,
//                             color: Colors.white,
//                             size: _isMobile(context) ? 20 : 22,
//                           ),
//                           onPressed: _search,
//                         ),
//                       ),
//                     ),
//                     onSubmitted: (_) => _search(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildLoadingIndicator() {
//     return Container(
//       padding: EdgeInsets.all(_isMobile(context) ? 32 : 40),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.white.withOpacity(0.1),
//             Colors.white.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         children: [
//           Stack(
//             alignment: Alignment.center,
//             children: [
//               Container(
//                 width: _isMobile(context) ? 50 : 60,
//                 height: _isMobile(context) ? 50 : 60,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                   ),
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF00D4AA).withOpacity(0.3),
//                       blurRadius: 15,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(
//                 width: _isMobile(context) ? 30 : 40,
//                 height: _isMobile(context) ? 30 : 40,
//                 child: const CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   strokeWidth: 3,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 16)),
//           Text(
//             'Searching safely for "$_query"...',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: _getResponsiveFontSize(context, 14),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 6)),
//           Text(
//             'Finding safe educational resources',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.7),
//               fontSize: _getResponsiveFontSize(context, 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // NEW: Inappropriate content warning widget
//   Widget _buildInappropriateContentWarning() {
//     return Container(
//       margin: EdgeInsets.symmetric(
//         horizontal: _isMobile(context) ? 16 : 20,
//         vertical: _isMobile(context) ? 16 : 20,
//       ),
//       padding: EdgeInsets.all(_isMobile(context) ? 20 : 30),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.red.withOpacity(0.15),
//             Colors.orange.withOpacity(0.08),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//           color: Colors.red.withOpacity(0.4),
//           width: 2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.red.withOpacity(0.2),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Warning Icon
//           Container(
//             padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.2),
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: Colors.red.withOpacity(0.5),
//                 width: 2,
//               ),
//             ),
//             child: Icon(
//               Icons.warning_rounded,
//               size: _isMobile(context) ? 50 : 60,
//               color: Colors.red,
//             ),
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 20)),
//
//           // Warning Title
//           Text(
//             '⚠️ Inappropriate Content Detected',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: _getResponsiveFontSize(context, 20),
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 16)),
//
//           // Warning Message
//           Container(
//             padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: Colors.red.withOpacity(0.3),
//               ),
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   'The search term "$_query" contains inappropriate content that is not suitable for students.',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: _getResponsiveFontSize(context, 14),
//                     height: 1.4,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: _getResponsiveSpacing(context, 12)),
//                 if (_inappropriateKeywordFound.isNotEmpty)
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: _isMobile(context) ? 8 : 12,
//                       vertical: _isMobile(context) ? 4 : 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.red.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(
//                         color: Colors.red.withOpacity(0.5),
//                       ),
//                     ),
//                     child: Text(
//                       'Blocked keyword: "$_inappropriateKeywordFound"',
//                       style: TextStyle(
//                         color: Colors.red.shade300,
//                         fontSize: _getResponsiveFontSize(context, 12),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 SizedBox(height: _getResponsiveSpacing(context, 12)),
//                 Text(
//                   'Please search for educational and appropriate content only.',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.8),
//                     fontSize: _getResponsiveFontSize(context, 12),
//                     fontStyle: FontStyle.italic,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 20)),
//
//           // Guidelines Section
//           Container(
//             padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: Colors.blue.withOpacity(0.3),
//               ),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.info_outline,
//                       color: Colors.blue,
//                       size: _isMobile(context) ? 18 : 20,
//                     ),
//                     SizedBox(width: _isMobile(context) ? 8 : 10),
//                     Text(
//                       'Search Guidelines:',
//                       style: TextStyle(
//                         color: Colors.blue.shade300,
//                         fontSize: _getResponsiveFontSize(context, 14),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: _getResponsiveSpacing(context, 12)),
//                 Text(
//                   '• Search for educational topics like programming, science, math\n'
//                       '• Look for tutorials, documentation, and learning resources\n'
//                       '• Avoid adult, violent, or inappropriate keywords\n'
//                       '• Focus on study and research-related material\n'
//                       '• Use professional and academic search terms',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.8),
//                     fontSize: _getResponsiveFontSize(context, 12),
//                     height: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 24)),
//
//           // Action Buttons
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     _controller.clear();
//                     setState(() {
//                       _query = '';
//                       _isInappropriateContent = false;
//                       _inappropriateKeywordFound = '';
//                       _googleLinks = [];
//                     });
//                   },
//                   icon: Icon(
//                     Icons.refresh,
//                     color: Colors.white,
//                     size: _isMobile(context) ? 16 : 18,
//                   ),
//                   label: Text(
//                     'Clear & Try Again',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: _getResponsiveFontSize(context, 12),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF00D4AA),
//                     padding: EdgeInsets.symmetric(
//                       horizontal: _isMobile(context) ? 16 : 20,
//                       vertical: _isMobile(context) ? 10 : 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: _isMobile(context) ? 12 : 16),
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: () => Navigator.pop(context),
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                     size: _isMobile(context) ? 16 : 18,
//                   ),
//                   label: Text(
//                     'Go Back',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: _getResponsiveFontSize(context, 12),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey.shade600,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: _isMobile(context) ? 16 : 20,
//                       vertical: _isMobile(context) ? 10 : 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // UPDATED: Results section with warning check
//   Widget _buildResultsSection() {
//     // IF INAPPROPRIATE CONTENT, SHOW WARNING INSTEAD OF RESULTS
//     if (_isInappropriateContent) {
//       return _buildInappropriateContentWarning();
//     }
//
//     // IF APPROPRIATE CONTENT, SHOW NORMAL RESULTS
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.white.withOpacity(0.12),
//                 Colors.white.withOpacity(0.06),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.2),
//               width: 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               // Safe search indicator
//               Container(
//                 padding: EdgeInsets.all(_isMobile(context) ? 6 : 8),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                   ),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.verified_user,
//                   color: Colors.white,
//                   size: _isMobile(context) ? 16 : 18,
//                 ),
//               ),
//               SizedBox(width: _isMobile(context) ? 10 : 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           'Safe Search Results',
//                           style: TextStyle(
//                             fontSize: _getResponsiveFontSize(context, 18),
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         SizedBox(width: _isMobile(context) ? 6 : 8),
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: _isMobile(context) ? 4 : 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(6),
//                             border: Border.all(
//                               color: Colors.green.withOpacity(0.5),
//                             ),
//                           ),
//                           child: Text(
//                             'FILTERED',
//                             style: TextStyle(
//                               color: Colors.green,
//                               fontSize: _getResponsiveFontSize(context, 8),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: _isMobile(context) ? 2 : 4),
//                     Text(
//                       'Found ${_googleLinks.length} safe results for "$_query"',
//                       style: TextStyle(
//                         color: const Color(0xFF00D4AA),
//                         fontSize: _getResponsiveFontSize(context, 12),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         SizedBox(height: _getResponsiveSpacing(context, 16)),
//
//         if (_googleLinks.isEmpty)
//           _buildEmptyState()
//         else
//           Column(
//             children: [
//               _buildLinksList(),
//               SizedBox(height: _getResponsiveSpacing(context, 20)),
//               _buildVideosButton(),
//             ],
//           ),
//       ],
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Container(
//       padding: EdgeInsets.all(_isMobile(context) ? 32 : 40),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.white.withOpacity(0.1),
//             Colors.white.withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(_isMobile(context) ? 12 : 16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.orange.withOpacity(0.3),
//                   Colors.orange.withOpacity(0.1),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Icon(
//               Icons.search_off_rounded,
//               size: _isMobile(context) ? 40 : 48,
//               color: Colors.orange,
//             ),
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 16)),
//           Text(
//             'No Safe Results Found',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: _getResponsiveFontSize(context, 16),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: _getResponsiveSpacing(context, 6)),
//           Text(
//             'Try different keywords or check spelling',
//             style: TextStyle(
//               color: Colors.white.withOpacity(0.7),
//               fontSize: _getResponsiveFontSize(context, 12),
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLinksList() {
//     return ListView.separated(
//       physics: const NeverScrollableScrollPhysics(),
//       shrinkWrap: true,
//       itemCount: _googleLinks.length,
//       separatorBuilder: (context, index) => SizedBox(height: _getResponsiveSpacing(context, 12)),
//       itemBuilder: (context, index) {
//         final link = _googleLinks[index];
//         final isSaved = _isLinkSaved(link.link);
//
//         return Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Colors.white.withOpacity(0.12),
//                 Colors.white.withOpacity(0.06),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: isSaved
//                   ? const Color(0xFF00D4AA).withOpacity(0.5)
//                   : Colors.white.withOpacity(0.2),
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => _openLink(link.link),
//               borderRadius: BorderRadius.circular(16),
//               child: Padding(
//                 padding: EdgeInsets.all(_isMobile(context) ? 16 : 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(_isMobile(context) ? 6 : 8),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: isSaved
//                                   ? [Colors.orange, Colors.deepOrange]
//                                   : [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                             ),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Icon(
//                             Icons.verified,
//                             color: Colors.white,
//                             size: _isMobile(context) ? 14 : 16,
//                           ),
//                         ),
//                         SizedBox(width: _isMobile(context) ? 10 : 12),
//
//                         Expanded(
//                           child: Text(
//                             link.title,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: _getResponsiveFontSize(context, 14),
//                               height: 1.3,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         SizedBox(width: _isMobile(context) ? 8 : 12),
//
//                         // Safe indicator
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: _isMobile(context) ? 4 : 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(6),
//                             border: Border.all(
//                               color: Colors.green.withOpacity(0.5),
//                             ),
//                           ),
//                           child: Text(
//                             'SAFE',
//                             style: TextStyle(
//                               color: Colors.green,
//                               fontSize: _getResponsiveFontSize(context, 8),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: _isMobile(context) ? 8 : 12),
//
//                         AnimatedBuilder(
//                           animation: _saveAnimation,
//                           builder: (context, child) {
//                             return Transform.scale(
//                               scale: _saveAnimation.value,
//                               child: Container(
//                                 padding: EdgeInsets.all(_isMobile(context) ? 8 : 10),
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     colors: isSaved
//                                         ? [Colors.orange, Colors.deepOrange]
//                                         : [Color(0xFF00D4AA), Color(0xFF00A8CC)],
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: isSaved
//                                           ? Colors.orange.withOpacity(0.3)
//                                           : const Color(0xFF00D4AA).withOpacity(0.3),
//                                       blurRadius: 8,
//                                       offset: const Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                                 child: InkWell(
//                                   onTap: () => _toggleSaveLink(link),
//                                   borderRadius: BorderRadius.circular(12),
//                                   child: Icon(
//                                     isSaved
//                                         ? Icons.bookmark_remove_rounded
//                                         : Icons.bookmark_add_rounded,
//                                     color: Colors.white,
//                                     size: _isMobile(context) ? 16 : 18,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: _getResponsiveSpacing(context, 10)),
//
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: _isMobile(context) ? 10 : 12,
//                         vertical: _isMobile(context) ? 4 : 6,
//                       ),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: isSaved
//                               ? [Colors.orange.withOpacity(0.3), Colors.deepOrange.withOpacity(0.2)]
//                               : [const Color(0xFF00D4AA).withOpacity(0.2), const Color(0xFF00A8CC).withOpacity(0.1)],
//                         ),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: isSaved
//                               ? Colors.orange.withOpacity(0.5)
//                               : const Color(0xFF00D4AA).withOpacity(0.3),
//                           width: 1,
//                         ),
//                       ),
//                       child: Text(
//                         link.link,
//                         style: TextStyle(
//                           color: isSaved ? Colors.orange : const Color(0xFF00D4AA),
//                           fontSize: _getResponsiveFontSize(context, 10),
//                           fontWeight: FontWeight.w500,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     SizedBox(height: _getResponsiveSpacing(context, 8)),
//
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.shield_outlined,
//                           size: _isMobile(context) ? 12 : 14,
//                           color: Colors.green,
//                         ),
//                         SizedBox(width: _isMobile(context) ? 4 : 6),
//                         Text(
//                           'Safe content • Tap to open',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.7),
//                             fontSize: _getResponsiveFontSize(context, 10),
//                           ),
//                         ),
//                         const Spacer(),
//                         if (isSaved) ...[
//                           Icon(
//                             Icons.check_circle_rounded,
//                             size: _isMobile(context) ? 12 : 14,
//                             color: Colors.orange,
//                           ),
//                           SizedBox(width: _isMobile(context) ? 4 : 6),
//                           Text(
//                             'Saved in notes',
//                             style: TextStyle(
//                               color: Colors.orange,
//                               fontSize: _getResponsiveFontSize(context, 10),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildVideosButton() {
//     return Container(
//       width: double.infinity,
//       height: _isMobile(context) ? 48 : 56,
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Colors.purple, Colors.deepPurple],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.purple.withOpacity(0.3),
//             blurRadius: 15,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () {
//             HapticFeedback.lightImpact();
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => VideoPage(topic: _query),
//               ),
//             );
//           },
//           borderRadius: BorderRadius.circular(16),
//           child: Center(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.play_circle_filled_rounded,
//                   color: Colors.white,
//                   size: _isMobile(context) ? 20 : 24,
//                 ),
//                 SizedBox(width: _isMobile(context) ? 8 : 12),
//                 Text(
//                   "View Safe Related Videos",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: _getResponsiveFontSize(context, 14),
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
