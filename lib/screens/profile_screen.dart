import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  final String currentUserId;
  const ProfileScreen({super.key, required this.currentUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  XFile? _image;
  Uint8List? _webImage;
  bool _loading = false;
  Map<String, dynamic>? _userData;

  final supabase = Supabase.instance.client;
  final bucketName = "profile_pictures";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', widget.currentUserId)
          .single();

      _userData = response;
      _nameController.text = _userData?['name'] ?? '';
      setState(() {});
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImage = bytes;
        _image = picked;
      });
    } else {
      setState(() => _image = picked);
    }
  }

  Future<String?> _uploadToSupabase() async {
    try {
      final fileName =
          "${widget.currentUserId}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

      if (kIsWeb) {
        await supabase.storage.from(bucketName).uploadBinary(
              fileName,
              _webImage!,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
              ),
            );
      } else {
        await supabase.storage.from(bucketName).upload(
              fileName,
              File(_image!.path),
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
              ),
            );
      }

      return supabase.storage.from(bucketName).getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Supabase upload error: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _loading = true);

    try {
      String? profileUrl = _userData?['profile_url'];

      // Upload image if selected
      if (_image != null) {
        final uploadedUrl = await _uploadToSupabase();
        if (uploadedUrl != null) profileUrl = uploadedUrl;
      }

      // Update Supabase database
      await supabase.from('users').update({
        'name': _nameController.text.trim(),
        'profile_url': profileUrl,
      }).eq('id', widget.currentUserId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }

      // Reload user data
      await _loadUserData();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentProfileUrl = _userData!['profile_url'] ?? '';

    ImageProvider? avatarImage;

    if (kIsWeb && _webImage != null) {
      avatarImage = MemoryImage(_webImage!) as ImageProvider;
    } else if (_image != null && !kIsWeb) {
      avatarImage = FileImage(File(_image!.path)) as ImageProvider;
    } else if (currentProfileUrl.isNotEmpty) {
      avatarImage = NetworkImage(currentProfileUrl) as ImageProvider;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: avatarImage,
              onBackgroundImageError: avatarImage is NetworkImage
                  ? (exception, stackTrace) {
                      debugPrint('Error loading profile image: $exception');
                    }
                  : null,
              child: avatarImage == null
                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                  : null,
              backgroundColor: Colors.pinkAccent.withOpacity(0.3),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),

          const SizedBox(height: 16),

          Text(
            _userData!['email'],
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 24),

          // Theme selector buttons
          const Text(
            'Select Theme:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  ThemeService.setTheme(AppTheme.light);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                ),
                child:
                    const Text('Light', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  ThemeService.setTheme(AppTheme.modern);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child:
                    const Text('Modern', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  ThemeService.setTheme(AppTheme.beautifulDark);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child:
                    const Text('Dark', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  ThemeService.setTheme(AppTheme.succulentBlue);
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                ),
                child:
                    const Text('Blue', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _loading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Update Profile"),
          ),
        ],
      ),
    );
  }
}
