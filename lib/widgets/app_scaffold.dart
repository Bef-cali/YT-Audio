// lib/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'mini_player.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final FloatingActionButton? floatingActionButton;
  final bool showMiniPlayer;

  const AppScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showMiniPlayer = true,  // default to showing the mini player
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a stylized bottom navigation bar if one is provided
    Widget? styledBottomNavBar;
    if (bottomNavigationBar != null) {
      styledBottomNavBar = Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Margin from edges
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0), // Rounded corners
          child: bottomNavigationBar,
        ),
      );
    }
    
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          // Main content expands to fill available space
          Expanded(child: body),
          
          // Mini player shown conditionally
          if (showMiniPlayer) const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: styledBottomNavBar,
      floatingActionButton: floatingActionButton,
    );
  }
}