// lib/widgets/audio_item_widget.dart
import 'package:flutter/material.dart';
import '../models/audio_item.dart';
import '../screens/player_screen.dart';

class AudioItemWidget extends StatelessWidget {
  final AudioItem audio;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showMoreOptions;
  final VoidCallback? onMoreOptions;

  const AudioItemWidget({
    Key? key,
    required this.audio,
    required this.isPlaying,
    required this.onPlay,
    required this.onDelete,
    this.onTap,
    this.onLongPress,
    this.showMoreOptions = false,
    this.onMoreOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap ?? () => _navigateToPlayerScreen(context),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail or placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: audio.thumbnailFile != null
                        ? Image.file(
                            audio.thumbnailFile!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.music_note, size: 30),
                  ),
                  const SizedBox(width: 12),
                  // Title and artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          audio.artist ?? 'Unknown Artist',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    onPressed: () {
                      // First play/pause the audio
                      onPlay();
                      
                      // Then navigate to player screen (only if we're playing)
                      if (!isPlaying) {
                        _navigateToPlayerScreen(context);
                      }
                    },
                  ),
                  if (showMoreOptions)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: onMoreOptions,
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                ],
              ),
              // Storage location indication
              if (audio.publicPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 62.0),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Saved in: ${audio.displayPath}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Display duration and file size
              if (audio.duration != null || audio.fileSize != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 62.0),
                  child: Row(
                    children: [
                      if (audio.duration != null) ...[
                        const Icon(Icons.timer, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          audio.formattedDuration,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (audio.duration != null && audio.fileSize != null)
                        const SizedBox(width: 12),
                      if (audio.fileSize != null) ...[
                        const Icon(Icons.data_usage, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          audio.formattedFileSize,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to navigate to player screen
  void _navigateToPlayerScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(audioItem: audio),
      ),
    );
  }
}