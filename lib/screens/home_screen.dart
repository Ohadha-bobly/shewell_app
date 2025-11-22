import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shewell_app/services/theme_service.dart';
import 'users_list_screen.dart';
import 'tracker_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import 'clinic_finder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  final supabase = Supabase.instance.client;
  String? _userProfileUrl;

  @override
  void initState() {
    super.initState();

    final user = supabase.auth.currentUser;

    _screens = [
      const TrackerScreen(),
      const ChatbotScreen(),
      const UsersListScreen(),
      const CommunityScreen(),
      const ClinicFinderScreen(),
      ProfileScreen(currentUserId: supabase.auth.currentUser?.id ?? ''),
    ];

    _loadUserProfile();
    _setUserStatus(true);
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final userData =
          await supabase.from('users').select().eq('id', user.id).maybeSingle();

      if (userData == null) {
        debugPrint('No user row found for id=${user.id}');
        return;
      }

      setState(() {
        final raw = userData['profile_url'];
        _userProfileUrl = (raw is String && raw.trim().isNotEmpty) ? raw : null;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  void dispose() {
    _setUserStatus(false);
    super.dispose();
  }

  Future<void> _setUserStatus(bool isOnline) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('users').update({
        'online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating user status: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showThemeMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Theme',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.light_mode, color: Colors.pink),
              title: const Text('Light'),
              onTap: () {
                ThemeService.setTheme(AppTheme.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.architecture, color: Colors.deepPurple),
              title: const Text('Modern'),
              onTap: () {
                ThemeService.setTheme(AppTheme.modern);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.redAccent),
              title: const Text('Beautiful Dark'),
              onTap: () {
                ThemeService.setTheme(AppTheme.beautifulDark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.cyan),
              title: const Text('Succulent Blue'),
              onTap: () {
                ThemeService.setTheme(AppTheme.succulentBlue);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SheWell'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    currentUserId: supabase.auth.currentUser?.id ?? '',
                  ),
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: _userProfileUrl != null
                  ? NetworkImage(_userProfileUrl!)
                  : null,
              child: _userProfileUrl == null ? const Icon(Icons.person) : null,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: _showThemeMenu,
            tooltip: 'Change Theme',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Tracker'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Community'),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Clinics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
