// lib/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_library.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioLibrary>(
      builder: (context, library, child) {
        // Only show if there's a current track (playing or paused)
        if (library.currentlyPlaying == null) {
          return const SizedBox.shrink();
        }

        // Always use the currently loaded track for UI
        final audio = library.currentlyPlaying!;
        final isPlaying = library.isPlaying;
        
        // Wrap in a padding container for margin from edges
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
            child: Material(
              color: Colors.transparent, // Make background transparent for ripple effect
              child: GestureDetector(
                onTap: () {
                  // Navigate to player screen with the current track
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(audioItem: audio),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.7),
                        Theme.of(context).primaryColor.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Thumbnail with rounded corners
                        Hero(
                          tag: 'audio_thumbnail_${audio.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: audio.thumbnailPath != null
                                ? Image.file(
                                    audio.thumbnailFile!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey.shade800,
                                    child: const Icon(
                                      Icons.music_note,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title and artist info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Hero(
                                tag: 'audio_title_${audio.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    audio.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Hero(
                                tag: 'audio_artist_${audio.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    audio.artist ?? 'Unknown Artist',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Play/pause button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                isPlaying 
                                    ? Icons.pause_rounded 
                                    : Icons.play_arrow_rounded,
                                key: ValueKey<bool>(isPlaying),
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                library.pause();
                              } else {
                                library.play();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}