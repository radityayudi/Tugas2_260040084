import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'book_api_service.dart';
import 'book_model.dart';
import 'book_photo_service.dart';
import 'book_viewmodel.dart';

class FormBukuPage extends StatefulWidget {
  final BookViewModel viewModel;
  final Book? book;

  const FormBukuPage({super.key, required this.viewModel, this.book});

  @override
  State<FormBukuPage> createState() => _FormBukuPageState();
}

class _FormBukuPageState extends State<FormBukuPage> {
  final _formKey = GlobalKey<FormState>();
  final BookPhotoService _photoService = BookPhotoService();

  late TextEditingController _judulController;
  late TextEditingController _penulisController;
  late TextEditingController _kategoriController;
  late TextEditingController _deskripsiController;
  late TextEditingController _tanggalController;
  String _selectedStatus = 'Tersedia';

  String? _fotoPath;
  bool _clearFoto = false;
  String? _openLibraryKey;
  bool _isPickingPhoto = false;
  bool _isSaving = false;
  bool _showValidationWarning = false;

  final List<String> _statusList = ['Tersedia', 'Dipinjam'];
  Timer? _debounce;
  Timer? _snackBarTimer;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.book?.judul ?? '');
    _penulisController = TextEditingController(text: widget.book?.penulis ?? '');
    _kategoriController = TextEditingController(text: widget.book?.kategori ?? '');
    _deskripsiController = TextEditingController(text: widget.book?.deskripsi ?? '');
    _tanggalController = TextEditingController(text: widget.book?.tanggal ?? '');
    if (widget.book != null) {
      _selectedStatus = widget.book!.status;
      _fotoPath = widget.book!.imagePath;
      _openLibraryKey = widget.book!.openLibraryKey;
    }

    // Pastikan sisa hasil pencarian sebelumnya bersih saat form dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewModel.clearSearchResults();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _snackBarTimer?.cancel();
    _judulController.dispose();
    _penulisController.dispose();
    _kategoriController.dispose();
    _deskripsiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  void _onJudulChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.viewModel.searchBooksFromApi(value);
    });
  }

  void _pilihSaranBuku(BookSearchSuggestion suggestion) {
    _debounce?.cancel();
    setState(() {
      _openLibraryKey = suggestion.openLibraryKey;
      _judulController.text = suggestion.title;
      _penulisController.text = suggestion.author;

      if (suggestion.category != null && suggestion.category!.trim().isNotEmpty) {
        _kategoriController.text = suggestion.category!.trim();
      } else {
        _kategoriController.clear();
      }

      if (suggestion.description != null && suggestion.description!.trim().isNotEmpty) {
        _deskripsiController.text = suggestion.description!.trim();
      } else {
        _deskripsiController.clear();
      }
    });
    widget.viewModel.clearSearchResults();
  }

  Future<void> _ambilFotoKamera() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);

    final result = await _photoService.captureFromCameraWithFallback();

    if (!mounted) return;
    setState(() {
      _isPickingPhoto = false;
      if (result.filePath != null) {
        _fotoPath = result.filePath;
        _clearFoto = false;
      }
    });

    if (result.noticeMessage != null) {
      _snackBarTimer?.cancel();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.noticeMessage!),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange.shade800,
            action: (!kIsWeb && result.openSettingsSuggested)
                ? SnackBarAction(
                    label: 'Pengaturan',
                    textColor: Colors.white,
                    onPressed: () {
                      _snackBarTimer?.cancel();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      openAppSettings();
                    },
                  )
                : null,
          ),
        );

      _snackBarTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    }
  }

  Future<void> _pilihFotoGaleri() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);

    final result = await _photoService.pickFromGallery();

    if (!mounted) return;
    setState(() {
      _isPickingPhoto = false;
      if (result.filePath != null) {
        _fotoPath = result.filePath;
        _clearFoto = false;
      }
    });

    if (result.noticeMessage != null && result.filePath == null) {
      _snackBarTimer?.cancel();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.noticeMessage!),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange.shade800,
          ),
        );
    }
  }

  void _hapusFoto() {
    setState(() {
      _fotoPath = null;
      _clearFoto = true;
    });
  }

  Widget _buildFotoPreview(String path) {
    if (kIsWeb) {
      return Image.network(
        path,
        width: 76,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 76,
          height: 100,
          color: Colors.grey[200],
          child: const Icon(Icons.menu_book_rounded, color: Colors.grey),
        ),
      );
    }

    return Image.file(
      File(path),
      width: 76,
      height: 100,
      fit: BoxFit.cover,
    );
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    DateTime initial = DateTime.now();
    if (_tanggalController.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_tanggalController.text);
      if (parsed != null) {
        initial = parsed;
      }
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1500),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _tanggalController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _simpan() async {
    if (_isSaving) return;

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() => _showValidationWarning = true);
      return;
    }

    setState(() {
      _showValidationWarning = false;
      _isSaving = true;
    });

    final isAdding = widget.book == null;
    final judul = _judulController.text.trim();
    final penulis = _penulisController.text.trim();
    final kategori = _kategoriController.text.trim();
    final deskripsi = _deskripsiController.text.trim();
    final tanggal = _tanggalController.text.trim();

    if (isAdding) {
      await widget.viewModel.addBook(
        judul,
        penulis,
        kategori,
        deskripsi,
        tanggal,
        _selectedStatus,
        imagePath: _fotoPath,
        openLibraryKey: _openLibraryKey,
      );
    } else {
      await widget.viewModel.editBook(
        widget.book!,
        judul,
        penulis,
        kategori,
        deskripsi,
        tanggal,
        _selectedStatus,
        imagePath: _fotoPath,
        openLibraryKey: _openLibraryKey,
        clearImage: _clearFoto,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    _snackBarTimer?.cancel();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdding
              ? 'Buku berhasil ditambahkan!'
              : 'Buku berhasil diperbarui!',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.book != null;
    final vm = widget.viewModel;
    final hasPhoto = _photoService.fileExists(_fotoPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Buku' : 'Tambah Buku Baru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: 'Judul Buku (Cari otomatis)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _judulController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _debounce?.cancel();
                            _judulController.clear();
                            _openLibraryKey = null;
                            vm.clearSearchResults();
                            setState(() {});
                          },
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: _onJudulChanged,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul tidak boleh kosong!' : null,
              ),
              ListenableBuilder(
                listenable: vm,
                builder: (context, _) {
                  final showEmptyState = !vm.isSearching &&
                      vm.searchError == null &&
                      vm.hasSearched &&
                      vm.searchResults.isEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.isSearching) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                      if (vm.searchError != null && !vm.isSearching) ...[
                        const SizedBox(height: 8),
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vm.searchError!,
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => vm.retrySearchBooks(),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (showEmptyState) ...[
                        const SizedBox(height: 8),
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Tidak ada buku yang cocok ditemukan. Kamu tetap bisa mengisi judul secara manual.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                      if (vm.searchResults.isNotEmpty && !vm.isSearching) ...[
                        const SizedBox(height: 8),
                        Card(
                          elevation: 2,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: vm.searchResults.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = vm.searchResults[index];
                              final subtitleParts = <String>[item.author];
                              if (item.category != null) {
                                subtitleParts.add(item.category!);
                              }

                              return ListTile(
                                title: Text(item.title),
                                subtitle: Text(subtitleParts.join(' • ')),
                                onTap: () => _pilihSaranBuku(item),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _penulisController,
                decoration: const InputDecoration(
                  labelText: 'Penulis',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Penulis harus diisi!' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kategoriController,
                decoration: const InputDecoration(
                  labelText: 'Kategori / Genre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Kategori harus diisi!' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Singkat (Opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                onTap: () => _pilihTanggal(context),
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pendataan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: Color.fromARGB(255, 0, 120, 189),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Tanggal harus dipilih!' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status Buku',
                  border: OutlineInputBorder(),
                ),
                items: _statusList
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              const SizedBox(height: 16),

              // --- Foto Buku / Catatan (Kamera + Fallback Galeri) ---
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Foto Buku',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (_openLibraryKey != null)
                            const Chip(
                              label: Text(
                                'Terhubung API',
                                style: TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ambil foto lewat kamera; jika izin ditolak/tidak tersedia, gunakan galeri.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPickingPhoto ? null : _ambilFotoKamera,
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Kamera'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 0, 120, 189),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isPickingPhoto ? null : _pilihFotoGaleri,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Galeri'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 0, 120, 189),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isPickingPhoto) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                      if (hasPhoto) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildFotoPreview(_fotoPath!),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Foto siap disimpan bersama data buku.',
                                    style: TextStyle(fontSize: 12.5),
                                  ),
                                  TextButton.icon(
                                    onPressed: _hapusFoto,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Hapus Foto',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              if (_showValidationWarning) ...[
                const Text(
                  'Silakan isi bagian yang masih merah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 172, 47, 38),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _isSaving ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH BUKU'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}