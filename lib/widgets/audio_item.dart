import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/audio_item.dart';

class FileInfoWidget extends StatelessWidget {
  final AudioItem audio;

  const FileInfoWidget({
    Key? key,
    required this.audio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Divider(),
            _buildInfoRow(
              context,
              'Location',
              audio.displayPath,
              Icons.folder,
              true,
            ),
            if (audio.fileSize != null)
              _buildInfoRow(
                context,
                'Size',
                audio.formattedFileSize,
                Icons.data_usage,
                false,
              ),
            if (audio.downloadDate != null)
              _buildInfoRow(
                context,
                'Downloaded',
                audio.formattedDate,
                Icons.calendar_today,
                false,
              ),
            if (audio.duration != null)
              _buildInfoRow(
                context,
                'Duration',
                audio.formattedDuration,
                Icons.timer,
                false,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'File location: ${audio.filePath}',
                    ),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Copy',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: audio.filePath));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Path copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Show Full Path'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool canCopy,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Copy to clipboard',
            ),
        ],
      ),
    );
  }
}