import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_manager.dart';

class DownloadsList extends StatelessWidget {
  const DownloadsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManager>(
      builder: (context, manager, child) {
        if (manager.downloads.isEmpty) {
          return const Center(
            child: Text('No active downloads'),
          );
        }

        return ListView.builder(
          itemCount: manager.downloads.length,
          itemBuilder: (context, index) {
            final download = manager.downloads[index];
            return ListTile(
              leading: download.thumbnail != null
                  ? Image.network(
                      download.thumbnail!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.music_note),
              title: Text(
                download.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: LinearProgressIndicator(
                value: download.progress / 100,
              ),
              trailing: Text('${download.progress.toStringAsFixed(0)}%'),
            );
          },
        );
      },
    );
  }
}