import 'dart:io';

class AudioItem {
  final String id;
  final String title;
  final String? artist;
  final String filePath;
  final String? thumbnailPath;
  final Duration? duration;
  final int? fileSize;
  final DateTime? downloadDate;
  final String? publicPath;
  final String? folderId;  // Added for folder support

  AudioItem({
    required this.id,
    required this.title,
    this.artist,
    required this.filePath,
    this.thumbnailPath,
    this.duration,
    this.fileSize,
    this.downloadDate,
    this.publicPath,
    this.folderId,  // Added for folder support
  });

  File? get thumbnailFile => 
      thumbnailPath != null ? File(thumbnailPath!) : null;
      
  File get audioFile => File(filePath);
  
  // Format the file size in a readable way (KB, MB)
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    
    if (fileSize! < 1024) {
      return '$fileSize B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
  
  // Format the duration in a readable way
  String get formattedDuration {
    if (duration == null) return 'Unknown';
    
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Format the download date
  String get formattedDate {
    if (downloadDate == null) return 'Unknown';
    
    return '${downloadDate!.day}/${downloadDate!.month}/${downloadDate!.year}';
  }
  
  // Get the display path (user-friendly)
  String get displayPath {
    return publicPath ?? filePath;
  }

  AudioItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? filePath,
    String? thumbnailPath,
    Duration? duration,
    int? fileSize,
    DateTime? downloadDate,
    String? publicPath,
    String? folderId,  // Added for folder support
  }) {
    return AudioItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      downloadDate: downloadDate ?? this.downloadDate,
      publicPath: publicPath ?? this.publicPath,
      folderId: folderId ?? this.folderId,  // Added for folder support
    );
  }
}