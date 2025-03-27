// lib/screens/folders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_library.dart';
import '../models/folder.dart';
import 'folder_contents_screen.dart';

class FoldersScreen extends StatelessWidget {
  const FoldersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioLibrary>(
      builder: (context, library, child) {
        // Get folders
        final folders = library.folders;
        
        // Get items not in any folder (default folder)
        final defaultItems = library.getItemsInFolder(null);
        
        if (folders.isEmpty && defaultItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Your library is empty'),
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
        
        return Column(
          children: [
            // Header with create folder button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Folders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder),
                    tooltip: 'Create Folder',
                    onPressed: () {
                      _showCreateFolderDialog(context);
                    },
                  ),
                ],
              ),
            ),
            
            // Folders list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => library.reloadItems(),
                child: ListView(
                  children: [
                    // Default folder (Downloads)
                    ListTile(
                      leading: const Icon(Icons.download, color: Colors.blue),
                      title: const Text('Downloads'),
                      subtitle: Text('${defaultItems.length} items'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FolderContentsScreen(
                              folderId: null,
                              folderName: 'Downloads',
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Divider between default and custom folders
                    if (folders.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Divider(),
                      ),
                    
                    // User-created folders
                    ...folders.map((folder) {
                      return ListTile(
                        leading: const Icon(Icons.folder, color: Colors.amber),
                        title: Text(folder.name),
                        subtitle: Text('${folder.itemCount} items'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                _showFolderOptionsMenu(context, library, folder);
                              },
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderContentsScreen(
                                folderId: folder.id,
                                folderName: folder.name,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showCreateFolderDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter a name for the folder',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                final library = Provider.of<AudioLibrary>(context, listen: false);
                library.createFolder(name);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Folder "$name" created'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _showFolderOptionsMenu(
    BuildContext context,
    AudioLibrary library,
    Folder folder,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename Folder'),
              onTap: () {
                Navigator.pop(context);
                _showRenameFolderDialog(context, library, folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Folder'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteFolderDialog(context, library, folder);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  void _showRenameFolderDialog(
    BuildContext context,
    AudioLibrary library,
    Folder folder,
  ) {
    final textController = TextEditingController(text: folder.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter a new name for the folder',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                library.renameFolder(folder.id, name);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Folder renamed to "$name"'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteFolderDialog(
    BuildContext context,
    AudioLibrary library,
    Folder folder,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete the folder "${folder.name}"? '
          'All items in this folder will be moved to Downloads.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              final folderName = folder.name;
              library.deleteFolder(folder.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Folder "$folderName" deleted'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}