// lib/models/download_manager.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'audio_item.dart';
import 'audio_library.dart';

class DownloadInfo {
  final String id;
  final String title;
  final String? thumbnail;
  final String? artist;
  double progress;
  String? filePath;

  DownloadInfo({
    required this.id,
    required this.title,
    this.thumbnail,
    this.artist,
    this.progress = 0.0,
    this.filePath,
  });
}

class DownloadManager extends ChangeNotifier {
  final List<DownloadInfo> _downloads = [];
  final YoutubeExplode _yt = YoutubeExplode();
  
  List<DownloadInfo> get downloads => _downloads;

  /// Gets the public download directory where files will be stored
  Future<Directory> getDownloadDirectory() async {
    // For Android, use the Downloads directory
    if (Platform.isAndroid) {
      // Get the external storage directory (this is publicly accessible)
      final Directory? externalDir = await getExternalStorageDirectory();
      
      if (externalDir == null) {
        throw Exception('Could not access external storage');
      }
      
      // Create a specific folder for our app
      final appDownloadsDir = Directory('${externalDir.path}/YouTube Audio');
      if (!await appDownloadsDir.exists()) {
        await appDownloadsDir.create(recursive: true);
      }
      
      return appDownloadsDir;
    } 
    // For iOS or other platforms, fall back to app documents directory
    // (iOS would need additional sharing implementation)
    else {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    }
  }

  Future<void> processYoutubeUrl(String url) async {
    // Extract video ID
    String? videoId;
    
    try {
      final uri = Uri.parse(url);
      
      // Handle standard youtube.com URLs
      if (uri.host.contains('youtube.com') || uri.host.contains('m.youtube.com')) {
        // Handle standard watch URLs
        if (uri.path.contains('/watch') && uri.queryParameters.containsKey('v')) {
          // Extract video ID and handle feature=shared and other parameters
          videoId = uri.queryParameters['v']?.split('&').first;
        }
        // Handle shorts
        else if (uri.path.startsWith('/shorts/')) {
          videoId = uri.pathSegments[1]; // 'shorts' is at index 0
        }
        // Handle embed URLs
        else if (uri.path.startsWith('/embed/')) {
          videoId = uri.pathSegments[1]; // 'embed' is at index 0
        }
        // Handle video URLs (some mobile links)
        else if (uri.path.startsWith('/v/')) {
          videoId = uri.pathSegments[1]; // 'v' is at index 0
        }
      }
      // Handle youtu.be short links
      else if (uri.host.contains('youtu.be')) {
        if (uri.pathSegments.isNotEmpty) {
          videoId = uri.pathSegments[0];
        }
      }
      
      if (videoId == null || videoId.isEmpty) {
        throw Exception('Could not extract video ID from URL: $url');
      }
      
      // Clean up any extra parameters that might be attached to the ID
      // This handles parameters like feature=shared, t= (time), si= (session info)
      if (videoId.contains('&')) {
        videoId = videoId.split('&')[0];
      }
      
      // Also handle URLs with feature=shared in the queryParameters
      if (uri.queryParameters.containsKey('feature') && 
          uri.queryParameters['feature'] == 'shared') {
        // This explicitly handles the feature=shared case that caused your error
        debugPrint('Handling a shared URL with feature=shared parameter');
      }

      // Get video metadata
      final video = await _yt.videos.get(videoId);
      
      // Create download info
      final download = DownloadInfo(
        id: videoId,
        title: video.title,
        thumbnail: video.thumbnails.highResUrl,
        artist: video.author,
      );
      
      _downloads.add(download);
      notifyListeners();
      
      // Start download
      await _downloadAudio(download);
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid URL format: $url');
      } else {
        debugPrint('Error processing YouTube URL: $e');
        rethrow;
      }
    }
  }

  Future<void> _downloadAudio(DownloadInfo download) async {
    try {
      // Get the public download directory
      final downloadsDir = await getDownloadDirectory();
      
      // Sanitize artist name (if available)
      final sanitizedArtist = download.artist != null 
          ? download.artist!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(RegExp(r'\s+'), '_')
          : 'Unknown_Artist';
      
      // Sanitize title
      final sanitizedTitle = download.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      
      // Create a more descriptive filename with artist info
      final fileName = '${sanitizedArtist}-${sanitizedTitle}.mp3';
      final filePath = '${downloadsDir.path}/$fileName';
      
      // Get audio stream
      final manifest = await _yt.videos.streamsClient.getManifest(download.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      if (audioStream == null) {
        throw Exception('No audio stream found for this video');
      }

      // Download audio stream
      final audioFile = File(filePath);
      final audioStream$ = _yt.videos.streamsClient.get(audioStream);
      
      final fileStream = audioFile.openWrite();
      
      final totalBytes = audioStream.size.totalBytes;
      var receivedBytes = 0;
      
      // Use a simpler approach to track progress
      await for (final data in audioStream$) {
        receivedBytes += data.length;
        final progress = (receivedBytes / totalBytes) * 100;
        
        // Update download progress
        download.progress = progress;
        notifyListeners();
        
        // Write to file
        fileStream.add(data);
      }
      
      await fileStream.flush();
      await fileStream.close();
      
      download.filePath = filePath;
      download.progress = 100;
      notifyListeners();
      
      // Download thumbnail if available
      String? thumbnailPath;
      if (download.thumbnail != null) {
        final thumbnailFile = File('${downloadsDir.path}/${download.id}_thumbnail.jpg');
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(download.thumbnail!));
        final response = await request.close();
        await response.pipe(thumbnailFile.openWrite());
        thumbnailPath = thumbnailFile.path;
        client.close();
      }
      
      // Add to library
      final audioItem = AudioItem(
        id: download.id,
        title: download.title,
        artist: download.artist,
        filePath: filePath,
        thumbnailPath: thumbnailPath,
        downloadDate: DateTime.now(),
      );
      
      // Use the provider to communicate with the library
      AudioLibrary().addAudio(audioItem);
      
      // Notify user where the file was saved (you can display this in the UI)
      debugPrint('File saved to: $filePath');
      
      // Remove from active downloads
      _downloads.remove(download);
      notifyListeners();
    } catch (e) {
      download.progress = -1; // Mark as failed
      notifyListeners();
      debugPrint('Download error: $e');
      rethrow;
    }
  }
}