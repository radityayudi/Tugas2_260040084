import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class PhotoCaptureResult {
  final String? filePath;
  final String sourceLabel; // e.g., 'Kamera' or 'Galeri'
  final String? noticeMessage;
  final bool fellBackToGallery;
  final bool openSettingsSuggested;

  const PhotoCaptureResult({
    this.filePath,
    required this.sourceLabel,
    this.noticeMessage,
    this.fellBackToGallery = false,
    this.openSettingsSuggested = false,
  });
}

class BookPhotoService {
  final ImagePicker _picker;

  BookPhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<PhotoCaptureResult> captureFromCameraWithFallback() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 82,
      );

      if (photo == null) {
        return const PhotoCaptureResult(
          sourceLabel: 'Kamera',
          noticeMessage: 'Pengambilan foto dibatalkan.',
        );
      }

      return PhotoCaptureResult(
        filePath: photo.path,
        sourceLabel: 'Kamera',
      );
    } on PlatformException catch (e, stack) {
      debugPrint(
        'BookPhotoService camera PlatformException: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      debugPrint('$stack');

      final code = e.code.toLowerCase();
      final isPermissionDenied = code.contains('denied') ||
          code.contains('permission') ||
          code.contains('restricted');

      if (isPermissionDenied) {
        return const PhotoCaptureResult(
          sourceLabel: 'Kamera',
          noticeMessage:
              'Akses kamera ditolak, silakan menggunakan galeri untuk memilih foto.\nAtau aktifkan kamera lewat pengaturan',
          openSettingsSuggested: true,
        );
      }

      if (!code.contains('camera')) {
        return PhotoCaptureResult(
          sourceLabel: 'Kamera',
          noticeMessage:
              'Gagal membuka kamera (${e.message ?? e.code}). Silakan pilih foto dari galeri.',
        );
      }

      // Fallback to gallery / image picker when camera is unavailable on device/emulator
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 82,
      );

      if (picked == null) {
        return const PhotoCaptureResult(
          sourceLabel: 'Galeri',
          fellBackToGallery: true,
          noticeMessage:
              'Kamera tidak tersedia. Alternatif galeri dibuka namun belum ada foto yang dipilih.',
        );
      }

      return PhotoCaptureResult(
        filePath: picked.path,
        sourceLabel: 'Galeri',
        fellBackToGallery: true,
        noticeMessage:
            'Kamera tidak tersedia — foto dipilih dari galeri sebagai alternatif.',
      );
    } catch (e, stack) {
      debugPrint('BookPhotoService unexpected camera error: $e');
      debugPrint('$stack');
      return const PhotoCaptureResult(
        sourceLabel: 'Kamera',
        noticeMessage: 'Terjadi kendala saat mengakses kamera.',
      );
    }
  }

  Future<PhotoCaptureResult> pickFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 82,
      );

      if (picked == null) {
        return const PhotoCaptureResult(
          sourceLabel: 'Galeri',
          noticeMessage: 'Pemilihan foto dari galeri dibatalkan.',
        );
      }

      return PhotoCaptureResult(
        filePath: picked.path,
        sourceLabel: 'Galeri',
      );
    } on PlatformException catch (e, stack) {
      debugPrint(
        'BookPhotoService gallery PlatformException: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      debugPrint('$stack');
      return PhotoCaptureResult(
        sourceLabel: 'Galeri',
        noticeMessage:
            'Akses galeri gagal/ditolak (${e.message ?? e.code}). Kamu tetap bisa menyimpan data buku tanpa foto.',
      );
    }
  }

  bool fileExists(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    if (kIsWeb) return true;
    return File(path).existsSync();
  }
}