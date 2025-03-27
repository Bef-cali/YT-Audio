// lib/utils/permissions_manager.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsManager {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // For Android 13+ (API 33+)
    if (await _isAndroid13OrHigher()) {
      final audioStatus = await Permission.audio.request();
      final imagesStatus = await Permission.photos.request();
      
      final granted = audioStatus.isGranted && imagesStatus.isGranted;
      
      if (!granted) {
        _showPermissionDialog(
          context, 
          'Storage permission is required to download and save audio files.'
        );
      }
      
      return granted;
    }
    // For Android 12 and below
    else {
      final status = await Permission.storage.request();
      
      if (!status.isGranted) {
        _showPermissionDialog(
          context, 
          'Storage permission is required to download and save audio files.'
        );
      }
      
      return status.isGranted;
    }
  }
  
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();
    
    if (!status.isGranted) {
      _showPermissionDialog(
        context, 
        'Notification permission is needed for audio player controls.'
      );
    }
    
    return status.isGranted;
  }
  
  static Future<void> requestAllRequiredPermissions(BuildContext context) async {
    // Request storage permissions
    await requestStoragePermission(context);
    
    // Request notification permissions
    await requestNotificationPermission(context);
  }
  
  static Future<bool> _isAndroid13OrHigher() async {
    // This is a simple check and might need refinement
    return await Permission.audio.status.isGranted != PermissionStatus.permanentlyDenied;
  }
  
  static void _showPermissionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}