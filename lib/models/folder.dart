// lib/models/folder.dart
import 'package:flutter/foundation.dart';

class Folder {
  final String id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int itemCount;
  
  Folder({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.itemCount = 0,
  });
  
  // Factory method to create from database record
  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
      itemCount: map['itemCount'] as int? ?? 0,
    );
  }
  
  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }
  
  // Copy with method for updates
  Folder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? itemCount,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}