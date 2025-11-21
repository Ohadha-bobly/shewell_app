import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final supabase = Supabase.instance.client;

  Future<String?> uploadFile({
    required File file,
    required String bucket,
  }) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final mimeType = lookupMimeType(file.path);

      final response = await supabase.storage.from(bucket).upload(
            fileName,
            file,
            fileOptions: FileOptions(contentType: mimeType),
          );

      if (response.isEmpty) {
        return null;
      }

      return supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  Future<void> savePendingUpload({
    required String uid,
    required Uint8List bytes,
    String? fileName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(bytes);
    final entry = {
      'uid': uid,
      'fileName': fileName ??
          '${uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      'bytes': encoded,
    };
    await prefs.setString('pending_upload', jsonEncode(entry));
  }

  Future<bool> processPendingUpload({
    String bucket = 'profile_pictures',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pending_upload');
    if (raw == null) return false;

    final Map<String, dynamic> entry = jsonDecode(raw);
    final pendingUid = entry['uid'] as String?;
    final pendingFileName = entry['fileName'] as String?;
    final bytesBase64 = entry['bytes'] as String?;
    if (pendingUid == null || bytesBase64 == null || pendingFileName == null) {
      await prefs.remove('pending_upload');
      return false;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    if (user.id != pendingUid) return false;

    try {
      final bytes = base64Decode(bytesBase64);

      if (kIsWeb) {
        await Supabase.instance.client.storage.from(bucket).uploadBinary(
              pendingFileName,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      } else {
        final tmpDir = await getTemporaryDirectory();
        final tmpFile = File('${tmpDir.path}/$pendingFileName');
        await tmpFile.create(recursive: true);
        await tmpFile.writeAsBytes(bytes, flush: true);

        await Supabase.instance.client.storage.from(bucket).upload(
              pendingFileName,
              tmpFile,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
      }

      final publicUrl = Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(pendingFileName);

      await Supabase.instance.client.from('users').update({
        'profile_url': publicUrl,
      }).eq('id', pendingUid);

      await prefs.remove('pending_upload');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('processPendingUpload error: $e');
      return false;
    }
  }
}
