import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_manager.dart';

class UrlInput extends StatefulWidget {
  const UrlInput({Key? key}) : super(key: key);

  @override
  State<UrlInput> createState() => _UrlInputState();
}

class _UrlInputState extends State<UrlInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isValidUrl = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateUrl(String url) {
    // Simple validation for YouTube URLs
    setState(() {
      _isValidUrl = url.isNotEmpty &&
          (url.contains('youtube.com/watch') || url.contains('youtu.be/'));
    });
  }

  Future<void> _processUrl() async {
    if (!_isValidUrl) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final manager = Provider.of<DownloadManager>(context, listen: false);
      await manager.processYoutubeUrl(_controller.text);
      _controller.clear();
      setState(() {
        _isValidUrl = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Paste YouTube URL',
            hintText: 'https://www.youtube.com/watch?v=...',
            border: OutlineInputBorder(),
          ),
          onChanged: _validateUrl,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isValidUrl && !_isLoading ? _processUrl : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.download),
          label: const Text('Download Audio'),
        ),
      ],
    );
  }
}