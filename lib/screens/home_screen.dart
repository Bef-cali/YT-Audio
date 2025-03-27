// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_manager.dart';
import '../widgets/url_input.dart';
import '../widgets/downloads_list.dart';
import '../widgets/app_scaffold.dart';
import 'folders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    // Use two screens: DownloadTab and FoldersScreen
    final List<Widget> _screens = [
      const DownloadTab(),
      const FoldersScreen(),
    ];
    
    return AppScaffold(
      appBar: AppBar(
        title: const Text('YT-Audio'),
        elevation: 0, // Remove shadow for modern look
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Transparent app bar
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color, // Text color matches body
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        // Override the default BottomNavigationBar theme
        data: Theme.of(context).copyWith(
          // Custom shape with more pronounced elevation and rounded corners
          splashColor: Colors.transparent, // Remove splash
          highlightColor: Colors.transparent, // Remove highlight
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Theme.of(context).primaryColor, // Use primary color for nav bar
          selectedItemColor: Colors.white, // White for selected items
          unselectedItemColor: Colors.white.withOpacity(0.6), // Translucent white for unselected
          type: BottomNavigationBarType.fixed, // Fixed type for consistent layout
          elevation: 8, // Add elevation for shadow
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.download_rounded),
              label: 'Download',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_rounded),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadTab extends StatelessWidget {
  const DownloadTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          UrlInput(),
          SizedBox(height: 16),
          Text(
            'Downloads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: DownloadsList(),
          ),
        ],
      ),
    );
  }
}