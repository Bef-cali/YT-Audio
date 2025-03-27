// lib/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_library.dart';
import '../widgets/audio_item_widget.dart';
import '../screens/player_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          // Add refresh button to app bar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh library',
            onPressed: () {
              // Get AudioLibrary instance without listening to changes
              final library = Provider.of<AudioLibrary>(context, listen: false);
              library.reloadItems();
              
              // Show a snackbar to confirm the refresh
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Library refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AudioLibrary>(
        builder: (context, library, child) {
          if (library.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No audio files in your library yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () => library.reloadItems(),
                  ),
                ],
              ),
            );
          }
          
          // Wrap ListView in RefreshIndicator for pull-to-refresh
          return RefreshIndicator(
            onRefresh: () => library.reloadItems(),
            child: ListView.builder(
              itemCount: library.items.length,
              itemBuilder: (context, index) {
                final audio = library.items[index];
                return AudioItemWidget(
                  audio: audio,
                  isPlaying: library.currentlyPlaying?.id == audio.id && library.isPlaying,
                  onPlay: () {
                    if (library.currentlyPlaying?.id == audio.id && library.isPlaying) {
                      library.pause();
                    } else {
                      library.playAudio(audio);
                    }
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Audio'),
                        content: const Text('Are you sure you want to delete this audio file?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              library.deleteAudio(audio);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  // Navigate to player screen when tapped
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(audioItem: audio),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}