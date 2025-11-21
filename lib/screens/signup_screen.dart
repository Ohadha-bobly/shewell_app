import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../services/storage_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  XFile? _image;
  Uint8List? _webImage;
  bool _loading = false;
  bool _obscurePassword = true;

  final supabase = Supabase.instance.client;

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

  Future<void> _signup() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile picture.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        emailRedirectTo: 'http://localhost:60953/#/',
      );

      if (response.user == null) {
        throw Exception("Signup failed. Try again.");
      }

      final uid = response.user!.id;

      if (response.session == null) {
        try {
          if (kIsWeb && _webImage != null) {
            await StorageService().savePendingUpload(
              uid: uid,
              bytes: _webImage!,
            );
          } else if (!kIsWeb && _image != null) {
            final bytes = await File(_image!.path).readAsBytes();
            await StorageService().savePendingUpload(
              uid: uid,
              bytes: bytes,
            );
          }
        } catch (e) {
          debugPrint('Failed to save pending upload: $e');
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Please check your email and confirm your account before logging in.',
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }

        return;
      }

      String? profileUrl;

      if (_image != null) {
        try {
          final fileName =
              "$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

          if (kIsWeb) {
            await supabase.storage
                .from('profile_pictures')
                .uploadBinary(fileName, _webImage!);
          } else {
            await supabase.storage
                .from('profile_pictures')
                .upload(fileName, File(_image!.path));
          }

          profileUrl =
              supabase.storage.from('profile_pictures').getPublicUrl(fileName);
        } catch (uploadError) {
          debugPrint("Image upload error: $uploadError");
        }
      }

      await supabase.from('users').insert({
        'id': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'profile_url': profileUrl ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.pink, Colors.pinkAccent]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Color.fromARGB(77, 255, 255, 255),
                      backgroundImage: kIsWeb && _webImage != null
                          ? MemoryImage(_webImage!) as ImageProvider
                          : (_image != null
                              ? FileImage(File(_image!.path)) as ImageProvider
                              : null),
                      child: _image == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ).animate().scale(duration: 600.ms),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: const Icon(Icons.person,
                                  color: Colors.pinkAccent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: const Icon(Icons.email,
                                  color: Colors.pinkAccent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: const Icon(Icons.lock,
                                  color: Colors.pinkAccent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
