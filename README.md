# katalog_buku

bagian yang diubah untuk tugas 2:
- Penambahan API OpenLibrary untuk mengisi form (Judul buku, Author, Kategori/Genre dan Deskripsi) yang juga membuat perubahan pada book_database.dart, book_model.dart dan book_viewmodel.dart karena operasi CRUD ada di sana
- Perubahan hirarki visual pada data_buku_page.dart, agar hirarki visual lebih baik (saya memisahkan antar data dari buku dengan bold teks dan italic)
-Penambahan fitur device, kamera dan image picker dari galeri untuk menambah foto pada katalog

Konfigurasi platform target yang didukung:
android/app/src/main/AndroidManifest.xml

cara menjalankan test:
flutter test


Cara menambah foto di galeri :
- drag dan drop foto pada emulator, tepatnya di file:///sdcard/Download
- buka git bash pada folder aplikasi
- adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/<nama.format> contoh:
adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/imag1es.jpg





## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
