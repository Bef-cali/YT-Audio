import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'audio_item.dart';
import 'folder.dart';

class AudioLibrary extends ChangeNotifier {
  final List<AudioItem> _items = [];
  final List<Folder> _folders = [];  // New field for folders
  final AudioPlayer _player = AudioPlayer();
  AudioItem? _currentlyPlaying;
  late Database _database;
  bool _initialized = false;

  AudioLibrary() {
    _initializeDatabase();
    _player.playerStateStream.listen((state) {
      notifyListeners();
    });
  }

  List<AudioItem> get items => _items;
  List<Folder> get folders => _folders;  // Getter for folders
  AudioItem? get currentlyPlaying => _currentlyPlaying;
  bool get isPlaying => _player.playing;

  Future<void> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = path.join(databasesPath, 'audio_library.db');

    _database = await openDatabase(
      dbPath,
      version: 3,  // Increased version for folder support
      onCreate: (db, version) async {
        // Create audio items table
        await db.execute('''
          CREATE TABLE audio_items(
            id TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            filePath TEXT,
            thumbnailPath TEXT,
            duration INTEGER,
            fileSize INTEGER,
            downloadDate INTEGER,
            publicPath TEXT,
            folder_id TEXT
          )
        ''');
        
        // Create folders table
        await db.execute('''
          CREATE TABLE folders(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdAt INTEGER,
            updatedAt INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add columns from version 1 to 2
          await db.execute('ALTER TABLE audio_items ADD COLUMN fileSize INTEGER');
          await db.execute('ALTER TABLE audio_items ADD COLUMN downloadDate INTEGER');
          await db.execute('ALTER TABLE audio_items ADD COLUMN publicPath TEXT');
        }
        
        if (oldVersion < 3) {
          // Add folder support
          await db.execute('ALTER TABLE audio_items ADD COLUMN folder_id TEXT');
          
          // Create folders table
          await db.execute('''
            CREATE TABLE folders(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              createdAt INTEGER,
              updatedAt INTEGER
            )
          ''');
        }
      },
    );

    // Load folders first, then items
    await _loadFolders();
    await _loadItems();
    
    _initialized = true;
    
    // Verify files exist after loading
    await verifyFilesExist();
  }

  // Load folders from database
  Future<void> _loadFolders() async {
    final records = await _database.query('folders');
    
    _folders.clear();
    for (final record in records) {
      // Count items in this folder
      final count = Sqflite.firstIntValue(await _database.rawQuery(
        'SELECT COUNT(*) FROM audio_items WHERE folder_id = ?',
        [record['id']],
      )) ?? 0;
      
      final folder = Folder.fromMap({
        ...record,
        'itemCount': count,
      });
      
      _folders.add(folder);
    }
  }

  Future<void> _loadItems() async {
    final records = await _database.query('audio_items');
    
    _items.clear();
    for (final record in records) {
      final item = AudioItem(
        id: record['id'] as String,
        title: record['title'] as String,
        artist: record['artist'] as String?,
        filePath: record['filePath'] as String,
        thumbnailPath: record['thumbnailPath'] as String?,
        duration: record['duration'] != null 
            ? Duration(milliseconds: record['duration'] as int) 
            : null,
        fileSize: record['fileSize'] as int?,
        downloadDate: record['downloadDate'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(record['downloadDate'] as int)
            : null,
        publicPath: record['publicPath'] as String?,
        folderId: record['folder_id'] as String?,  // Added for folder support
      );
      
      _items.add(item);
    }
    
    notifyListeners();
  }

  // Check if files still exist and remove missing files from the database
  Future<void> verifyFilesExist() async {
    if (!_initialized) await _initializeDatabase();
    
    bool hasChanges = false;
    final itemsToRemove = <AudioItem>[];
    
    for (final item in _items) {
      final file = File(item.filePath);
      if (!await file.exists()) {
        itemsToRemove.add(item);
        hasChanges = true;
      }
    }
    
    // Remove missing files from the database
    for (final item in itemsToRemove) {
      await _database.delete(
        'audio_items',
        where: 'id = ?',
        whereArgs: [item.id],
      );
      _items.remove(item);
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }

  // Format the file path into a user-friendly format
  String getFormattedPath(String filePath) {
    if (Platform.isAndroid) {
      // Extract the "YouTube Audio" part for Android
      final pathSegments = filePath.split('/');
      final youtubeAudioIndex = pathSegments.indexOf('YouTube Audio');
      
      if (youtubeAudioIndex >= 0 && youtubeAudioIndex + 1 < pathSegments.length) {
        return 'YouTube Audio/${pathSegments[youtubeAudioIndex + 1]}';
      }
    }
    
    // Default case: Just return the filename
    return path.basename(filePath);
  }

  Future<void> addAudio(AudioItem audio) async {
    if (!_initialized) await _initializeDatabase();
    
    // Load duration if not provided
    if (audio.duration == null) {
      try {
        final duration = await _player.setFilePath(audio.filePath);
        audio = audio.copyWith(duration: duration);
      } catch (e) {
        debugPrint('Error getting audio duration: $e');
      }
    }
    
    // Get file size
    try {
      final file = File(audio.filePath);
      final fileSize = await file.length();
      audio = audio.copyWith(fileSize: fileSize);
    } catch (e) {
      debugPrint('Error getting file size: $e');
    }
    
    // Set download date and public path
    audio = audio.copyWith(
      downloadDate: DateTime.now(),
      publicPath: getFormattedPath(audio.filePath),
    );
    
    // Add to database
    await _database.insert(
      'audio_items',
      {
        'id': audio.id,
        'title': audio.title,
        'artist': audio.artist,
        'filePath': audio.filePath,
        'thumbnailPath': audio.thumbnailPath,
        'duration': audio.duration?.inMilliseconds,
        'fileSize': audio.fileSize,
        'downloadDate': audio.downloadDate?.millisecondsSinceEpoch,
        'publicPath': audio.publicPath,
        'folder_id': audio.folderId,  // Added for folder support
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Add to memory list
    if (!_items.any((item) => item.id == audio.id)) {
      _items.add(audio);
      notifyListeners();
    }
  }
  
  /// Manually reload items from the database
  Future<void> reloadItems() async {
    if (!_initialized) await _initializeDatabase();
    
    // Reload folders and items from database
    await _loadFolders();
    await _loadItems();
    
    // Verify files still exist
    await verifyFilesExist();
    
    // _loadItems already calls notifyListeners()
  }
  
  Future<void> deleteAudio(AudioItem audio) async {
    if (!_initialized) await _initializeDatabase();
    
    // Stop playback if this is the current audio
    if (_currentlyPlaying?.id == audio.id) {
      await _player.stop();
      _currentlyPlaying = null;
    }
    
    // Delete from database
    await _database.delete(
      'audio_items',
      where: 'id = ?',
      whereArgs: [audio.id],
    );
    
    // Delete files
    try {
      final audioFile = File(audio.filePath);
      if (await audioFile.exists()) {
        await audioFile.delete();
        debugPrint('Deleted audio file: ${audio.filePath}');
      }
      
      if (audio.thumbnailPath != null) {
        final thumbnailFile = File(audio.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
          debugPrint('Deleted thumbnail file: ${audio.thumbnailPath}');
        }
      }
    } catch (e) {
      debugPrint('Error deleting files: $e');
    }
    
    // Remove from memory list
    _items.removeWhere((item) => item.id == audio.id);
    
    // Update folder item count if needed
    if (audio.folderId != null) {
      _updateFolderItemCount(audio.folderId!);
    }
    
    notifyListeners();
  }

  Future<void> playAudio(AudioItem audio) async {
    if (_currentlyPlaying?.id == audio.id && _player.playing) {
      await pause();
      return;
    }
    
    try {
      // First check if the file exists
      final file = File(audio.filePath);
      if (!await file.exists()) {
        debugPrint('Audio file not found: ${audio.filePath}');
        
        // Remove from library if file doesn't exist
        await deleteAudio(audio);
        return;
      }
      
      await _player.setFilePath(audio.filePath);
      await _player.play();
      _currentlyPlaying = audio;
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentlyPlaying != null) {
      await _player.play();
      notifyListeners();
    }
  }
  
  // Get the current playback position
  Stream<Duration> get positionStream => _player.positionStream;

  // Get the duration of the current track
  Stream<Duration?> get durationStream => _player.durationStream;

  // Method to seek to a specific position
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }
  
  // Get sorted items (newest first by default)
  List<AudioItem> getSortedItems({bool newestFirst = true}) {
    final sortedItems = List<AudioItem>.from(_items);
    sortedItems.sort((a, b) {
      final dateA = a.downloadDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.downloadDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return newestFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });
    return sortedItems;
  }

  // Search items by title or artist
  List<AudioItem> searchItems(String query) {
    if (query.isEmpty) return _items;
    
    final lowercaseQuery = query.toLowerCase();
    return _items.where((item) {
      final title = item.title.toLowerCase();
      final artist = (item.artist ?? '').toLowerCase();
      return title.contains(lowercaseQuery) || artist.contains(lowercaseQuery);
    }).toList();
  }
  
  // FOLDER MANAGEMENT METHODS
  
  // Create a new folder
  Future<Folder> createFolder(String name) async {
    if (!_initialized) await _initializeDatabase();
    
    final now = DateTime.now();
    final id = 'folder_${now.millisecondsSinceEpoch}';
    
    final folder = Folder(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    
    await _database.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    _folders.add(folder);
    notifyListeners();
    
    return folder;
  }
  
  // Rename a folder
  Future<void> renameFolder(String folderId, String newName) async {
    if (!_initialized) await _initializeDatabase();
    
    await _database.update(
      'folders',
      {
        'name': newName,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [folderId],
    );
    
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index >= 0) {
      _folders[index] = _folders[index].copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }
  
  // Delete a folder
  Future<void> deleteFolder(String folderId) async {
    if (!_initialized) await _initializeDatabase();
    
    // Get items in this folder
    final folderItems = getItemsInFolder(folderId);
    
    // Move items to the default folder (null)
    for (final item in folderItems) {
      await moveItemToFolder(item.id, null);
    }
    
    // Delete the folder
    await _database.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [folderId],
    );
    
    _folders.removeWhere((f) => f.id == folderId);
    notifyListeners();
  }
  
  // Move an item to a folder
  Future<void> moveItemToFolder(String itemId, String? folderId) async {
    if (!_initialized) await _initializeDatabase();
    
    // Get the item's current folder
    final item = _items.firstWhere((item) => item.id == itemId);
    final oldFolderId = item.folderId;
    
    // Update database
    await _database.update(
      'audio_items',
      {'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [itemId],
    );
    
    // Update memory model
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(folderId: folderId);
    }
    
    // Update folder item counts
    if (oldFolderId != null) {
      _updateFolderItemCount(oldFolderId);
    }
    if (folderId != null) {
      _updateFolderItemCount(folderId);
    }
    
    notifyListeners();
  }
  
  // Update folder item count
  Future<void> _updateFolderItemCount(String folderId) async {
    // Count items in this folder
    final count = Sqflite.firstIntValue(await _database.rawQuery(
      'SELECT COUNT(*) FROM audio_items WHERE folder_id = ?',
      [folderId],
    )) ?? 0;
    
    // Update memory model
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index >= 0) {
      _folders[index] = _folders[index].copyWith(itemCount: count);
    }
  }
  
  // Get items in a folder
  List<AudioItem> getItemsInFolder(String? folderId) {
    return _items.where((item) => item.folderId == folderId).toList();
  }

  @override
  void dispose() {
    _player.dispose();
    _database.close();
    super.dispose();
  }
}