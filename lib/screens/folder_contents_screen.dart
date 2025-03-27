// lib/screens/folder_contents_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_library.dart';
import '../models/audio_item.dart';
import '../models/folder.dart';
import '../widgets/audio_item_widget.dart';
import '../widgets/app_scaffold.dart';  // Import AppScaffold
import 'player_screen.dart';

class FolderContentsScreen extends StatelessWidget {
  final String? folderId;
  final String folderName;
  
  const FolderContentsScreen({
    Key? key,
    required this.folderId,
    required this.folderName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Replace Scaffold with AppScaffold
    return AppScaffold(
      appBar: AppBar(
        title: Text(folderName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh folder',
            onPressed: () {
              final library = Provider.of<AudioLibrary>(context, listen: false);
              library.reloadItems();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Folder refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AudioLibrary>(
        builder: (context, library, child) {
          final items = library.getItemsInFolder(folderId);
          
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No audio files in "$folderName"'),
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
          
          return RefreshIndicator(
            onRefresh: () => library.reloadItems(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final audio = items[index];
                return AudioItemWidget(
                  audio: audio,
                  isPlaying: library.currentlyPlaying?.id == audio.id && library.isPlaying,
                  onPlay: () {
                    if (library.currentlyPlaying?.id == audio.id && library.isPlaying) {
                      library.pause();
                    } else {
                      library.playAudio(audio);
                      // Navigate to player screen when play is pressed
                      if (library.currentlyPlaying?.id == audio.id) {
                        _navigateToPlayerScreen(context, audio);
                      }
                    }
                  },
                  onDelete: () {
                    _showDeleteAudioDialog(context, library, audio);
                  },
                  onLongPress: () {
                    _showMoveToFolderDialog(context, library, audio);
                  },
                  // Use a direct navigation function for tap
                  onTap: () => _navigateToPlayerScreen(context, audio),
                  showMoreOptions: true,
                  onMoreOptions: () {
                    _showAudioOptionsMenu(context, library, audio);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  // Helper method to navigate to player screen
  void _navigateToPlayerScreen(BuildContext context, AudioItem audio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(audioItem: audio),
      ),
    );
  }
  
  void _showDeleteAudioDialog(
    BuildContext context,
    AudioLibrary library,
    AudioItem audio,
  ) {
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              library.deleteAudio(audio);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audio file deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showAudioOptionsMenu(
    BuildContext context,
    AudioLibrary library,
    AudioItem audio,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_copy),
              title: const Text('Move to folder'),
              onTap: () {
                Navigator.pop(context);
                _showMoveToFolderDialog(context, library, audio);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_filled, color: Colors.green),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                library.playAudio(audio);
                // Navigate to player screen after playing
                _navigateToPlayerScreen(context, audio);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View details'),
              onTap: () {
                Navigator.pop(context);
                _showAudioDetailsDialog(context, audio);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAudioDialog(context, library, audio);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  void _showAudioDetailsDialog(
    BuildContext context,
    AudioItem audio,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', audio.title),
              if (audio.artist != null)
                _buildDetailRow('Artist', audio.artist!),
              if (audio.duration != null)
                _buildDetailRow('Duration', audio.formattedDuration),
              if (audio.fileSize != null)
                _buildDetailRow('Size', audio.formattedFileSize),
              if (audio.downloadDate != null)
                _buildDetailRow('Downloaded', audio.formattedDate),
              _buildDetailRow('Location', audio.displayPath),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  void _showMoveToFolderDialog(
    BuildContext context,
    AudioLibrary library,
    AudioItem audio,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Move "${audio.title}" to:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Default folder (Downloads)
                    ListTile(
                      leading: const Icon(Icons.download, color: Colors.blue),
                      title: const Text('Downloads'),
                      trailing: audio.folderId == null
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (audio.folderId != null) {
                          library.moveItemToFolder(audio.id, null);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Moved to Downloads'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Your Folders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // User-created folders
                    ...library.folders.map((folder) {
                      final isCurrentFolder = audio.folderId == folder.id;
                      
                      return ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(folder.name),
                        trailing: isCurrentFolder
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isCurrentFolder) {
                            library.moveItemToFolder(audio.id, folder.id);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Moved to ${folder.name}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    }),
                    
                    // Option to create a new folder
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.create_new_folder, color: Colors.green),
                      title: const Text('Create New Folder'),
                      onTap: () {
                        Navigator.pop(context);
                        _showCreateAndMoveDialog(context, library, audio);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showCreateAndMoveDialog(
    BuildContext context,
    AudioLibrary library,
    AudioItem audio,
  ) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create a new folder and move "${audio.title}" to it.'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'Enter a name for the new folder',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                // Create folder and move item
                final folder = await library.createFolder(name);
                library.moveItemToFolder(audio.id, folder.id);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Moved to new folder "$name"'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Create & Move'),
          ),
        ],
      ),
    );
  }
}