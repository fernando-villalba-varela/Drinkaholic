// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AvatarService {
  static final ImagePicker _picker = ImagePicker();

  Future<List<String>> loadAvatarAssets() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> map = jsonDecode(manifest);
    return map.keys
        .where(
          (k) =>
              k.startsWith('assets/avatars/') &&
              (k.endsWith('.png') ||
                  k.endsWith('.jpg') ||
                  k.endsWith('.jpeg') ||
                  k.endsWith('.gif') ||
                  k.endsWith('.webp')),
        )
        .toList();
  }

  Future<String?> pickAvatarFromAssets({
    required BuildContext context,
    required Set<String> used,
    String? current,
  }) async {
    final assets = await loadAvatarAssets();
    if (assets.isEmpty) return null;
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF00C9FF).withOpacity(.95),
        title: const Text('Elegir avatar', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: assets.length,
            itemBuilder: (_, i) {
              final path = assets[i];
              final isUsed = used.contains(path) && path != current;
              final isCurrent = current == path;
              return GestureDetector(
                onTap: isUsed ? null : () => Navigator.pop(context, path),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent
                          ? Colors.white
                          : isUsed
                          ? Colors.red.shade300
                          : Colors.white30,
                      width: isCurrent || isUsed ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<File?> takePhoto(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permiso de cámara denegado'), backgroundColor: Colors.redAccent));
      return null;
    }
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60);
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<bool> confirmDelete({required BuildContext context, required String title}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF00C9FF).withOpacity(.95),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}
