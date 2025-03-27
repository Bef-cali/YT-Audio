// lib/screens/player_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_item.dart';
import '../models/audio_library.dart';
import '../widgets/app_scaffold.dart';

class PlayerScreen extends StatefulWidget {
  final AudioItem audioItem;

  const PlayerScreen({Key? key, required this.audioItem}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  // Track state
  late AudioItem _currentAudio;
  bool _isPlayerReady = false;
  bool _isLoadingTrack = true;
  
  // Duration state
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _currentSliderValue = 0.0;
  bool _isSliderChanging = false;
  
  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _playPauseController;

  @override
  void initState() {
    super.initState();
    _currentAudio = widget.audioItem;
    
    // Setup animations
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Preload track data after first frame to avoid janky UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _playPauseController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final library = Provider.of<AudioLibrary>(context, listen: false);
    
    // Set initial loading state
    setState(() {
      _isLoadingTrack = true;
    });
    
    // Switch to the selected track if it's not already playing
    if (library.currentlyPlaying?.id != widget.audioItem.id) {
      await library.playAudio(widget.audioItem);
      // Short pause to ensure the track is loaded
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // Update UI state now that track is loaded
    if (mounted) {
      setState(() {
        _isPlayerReady = true;
        _isLoadingTrack = false;
        _currentAudio = widget.audioItem;
        
        // Set initial duration if available
        if (library.currentlyPlaying?.duration != null) {
          _duration = library.currentlyPlaying!.duration!;
        }
      });
    }

    // Listen for position updates only after player is ready
    library.positionStream.listen((position) {
      if (!_isSliderChanging && mounted) {
        setState(() {
          _position = position;
          _currentSliderValue = position.inMilliseconds.toDouble();
        });
      }
    });

    // Listen for duration updates
    library.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    
    // Track play state changes for animations
    final isPlaying = library.isPlaying;
    if (isPlaying) {
      _playPauseController.forward();
    } else {
      _playPauseController.reverse();
    }
  }
  
  // Gracefully handle track changes when navigating with prev/next buttons
  void _handleTrackChange(BuildContext context, AudioItem newTrack) {
    // Reset states
    setState(() {
      _currentAudio = newTrack;
      _position = Duration.zero;
      _currentSliderValue = 0;
      _duration = Duration.zero;
      _isLoadingTrack = true;
      _isPlayerReady = false;
    });
    
    // Re-initialize player with new track after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioLibrary>(
      builder: (context, library, child) {
        final isPlaying = library.isPlaying && library.currentlyPlaying?.id == _currentAudio.id;
        
        // Update play/pause animation state when playback state changes
        if (isPlaying && _playPauseController.status == AnimationStatus.dismissed) {
          _playPauseController.forward();
        } else if (!isPlaying && _playPauseController.status == AnimationStatus.completed) {
          _playPauseController.reverse();
        }
        
        final maxSliderValue = _duration.inMilliseconds.toDouble();
        
        // Use AppScaffold with showMiniPlayer set to false
        return AppScaffold(
          showMiniPlayer: false,  // Hide mini player on this screen
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.6),
                  Colors.black87,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App bar equivalent
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Now Playing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white),
                          onPressed: () {
                            _showFileInfo(context, _currentAudio);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Album art
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Hero(
                            tag: 'audio_thumbnail_${_currentAudio.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: _currentAudio.thumbnailFile != null
                                    ? Image.file(
                                        _currentAudio.thumbnailFile!,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.music_note,
                                          size: 100,
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Track info and controls
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Title and artist
                        Text(
                          _currentAudio.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_currentAudio.artist != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _currentAudio.artist!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 24),
                        
                        // Loading indicator during track preparation
                        if (_isLoadingTrack)
                          Column(
                            children: [
                              RotationTransition(
                                turns: _loadingController,
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading audio...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 72), // Spacing to match normal controls
                            ],
                          )
                        else
                          Column(
                            children: [
                              // Progress bar
                              SliderTheme(
                                data: SliderThemeData(
                                  thumbColor: Colors.white,
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                  trackShape: const RoundedRectSliderTrackShape(),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  min: 0.0,
                                  max: maxSliderValue > 0 ? maxSliderValue : 1.0,
                                  value: _currentSliderValue.clamp(0.0, maxSliderValue > 0 ? maxSliderValue : 1.0),
                                  onChanged: (value) {
                                    setState(() {
                                      _currentSliderValue = value;
                                      _isSliderChanging = true;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    _isSliderChanging = false;
                                    library.seekTo(Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                              
                              // Time indicators
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Playback controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    iconSize: 32,
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      // Play previous in library
                                      final currentIndex = library.items.indexWhere(
                                        (item) => item.id == _currentAudio.id
                                      );
                                      if (currentIndex > 0) {
                                        final prevTrack = library.items[currentIndex - 1];
                                        
                                        // Navigate with replacement to avoid back stack buildup
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayerScreen(
                                              audioItem: prevTrack,
                                            ),
                                          ),
                                        );
                                        
                                        // Update current player state
                                        _handleTrackChange(context, prevTrack);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 24),
                                  GestureDetector(
                                    onTap: _isPlayerReady
                                        ? () {
                                            if (isPlaying) {
                                              library.pause();
                                            } else {
                                              library.playAudio(_currentAudio);
                                            }
                                          }
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).primaryColor.withOpacity(0.5),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: AnimatedIcon(
                                        icon: AnimatedIcons.play_pause,
                                        progress: _playPauseController,
                                        color: Theme.of(context).primaryColor,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  IconButton(
                                    iconSize: 32,
                                    icon: const Icon(
                                      Icons.skip_next,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      // Play next in library
                                      final currentIndex = library.items.indexWhere(
                                        (item) => item.id == _currentAudio.id
                                      );
                                      if (currentIndex < library.items.length - 1) {
                                        final nextTrack = library.items[currentIndex + 1];
                                        
                                        // Navigate with replacement to avoid back stack buildup
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlayerScreen(
                                              audioItem: nextTrack,
                                            ),
                                          ),
                                        );
                                        
                                        // Update current player state
                                        _handleTrackChange(context, nextTrack);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
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
  
  // Show file info in a dialog
  void _showFileInfo(BuildContext context, AudioItem audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.title, 'Title', audio.title),
                if (audio.artist != null)
                  _buildInfoRow(Icons.person, 'Artist', audio.artist!),
                if (audio.duration != null)
                  _buildInfoRow(
                    Icons.timer, 
                    'Duration', 
                    audio.formattedDuration
                  ),
                if (audio.fileSize != null)
                  _buildInfoRow(
                    Icons.data_usage, 
                    'Size', 
                    audio.formattedFileSize
                  ),
                if (audio.downloadDate != null)
                  _buildInfoRow(
                    Icons.calendar_today, 
                    'Downloaded', 
                    audio.formattedDate
                  ),
                _buildInfoRow(
                  Icons.folder, 
                  'Location', 
                  audio.displayPath
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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