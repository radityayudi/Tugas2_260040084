import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'book_model.dart';
import 'book_photo_service.dart';
import 'book_viewmodel.dart';
import 'form_buku_page.dart';

class DataBukuPage extends StatefulWidget {
  final BookViewModel? viewModel;

  const DataBukuPage({super.key, this.viewModel});

  @override
  State<DataBukuPage> createState() => _DataBukuPageState();
}

class _DataBukuPageState extends State<DataBukuPage> {
  BookViewModel? _ownedViewModel;
  final BookPhotoService _photoService = BookPhotoService();

  BookViewModel get _viewModel => widget.viewModel ?? _ownedViewModel!;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel == null) {
      _ownedViewModel = BookViewModel();
    }
    _viewModel.fetchBooks();
  }

  @override
  void dispose() {
    _ownedViewModel?.dispose();
    super.dispose();
  }

  Widget _buildCardThumbnail(String? imagePath) {
    final hasPhoto = _photoService.fileExists(imagePath);

    if (!hasPhoto || imagePath == null) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.menu_book_rounded,
          color: Color.fromARGB(255, 0, 120, 189),
          size: 32,
        ),
      );
    }

    if (kIsWeb) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: Colors.grey[200],
          child: const Icon(
            Icons.menu_book_rounded,
            color: Color.fromARGB(255, 0, 120, 189),
            size: 32,
          ),
        ),
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog Buku'), centerTitle: true),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.books.isEmpty) {
            return const Center(
              child: Text('Belum ada data buku. Tekan + untuk menambah.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _viewModel.books.length,
            itemBuilder: (context, index) {
              final book = _viewModel.books[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PHOTO (Left)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 74,
                          height: 102,
                          child: _buildCardThumbnail(book.imagePath),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. BOOK / API DATA (Middle)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Judul
                            Text(
                              book.judul,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            if (book.openLibraryKey != null &&
                                book.openLibraryKey!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Open Library',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),

                            // 2. Penulis & Kategori
                            Text(
                              'Penulis: ${book.penulis}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            if (book.kategori.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Kategori: ${book.kategori}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],

                            const SizedBox(height: 5),

                            // 3. Status & Tanggal Pencatatan
                            Text(
                              'Status: ${book.status}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tanggal Pencatatan: ${book.tanggal}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.normal,
                              ),
                            ),

                            // 4. Deskripsi: italic & maksimal 3 baris
                            if (book.deskripsi.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                book.deskripsi,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[800],
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // 3. EDIT & DELETE BUTTONS (Right)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color.fromARGB(255, 92, 203, 255),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FormBukuPage(
                                    viewModel: _viewModel,
                                    book: book,
                                  ),
                                ),
                              );
                              _viewModel.fetchBooks();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _konfirmasiHapus(context, book),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormBukuPage(viewModel: _viewModel),
            ),
          );
          _viewModel.fetchBooks();
        },
        backgroundColor: const Color.fromARGB(255, 162, 213, 255),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _konfirmasiHapus(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Yakin ingin menghapus "${book.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _viewModel.removeBook(book.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}