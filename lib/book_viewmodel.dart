import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'book_api_service.dart';
import 'book_model.dart';
import 'book_database.dart';

class BookViewModel extends ChangeNotifier {
  final BookApiService _apiService;

  BookViewModel({BookApiService? apiService})
      : _apiService = apiService ?? BookApiService();

  // --- State CRUD SQLite / In-Memory Web ---
  List<Book> _books = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;

  // --- State Pencarian Open Library API ---
  List<BookSearchSuggestion> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String _lastSearchQuery = '';
  bool _hasSearched = false;

  List<BookSearchSuggestion> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  bool get hasSearched => _hasSearched;

  // Ambil data untuk ditampilkan di layar
  Future<void> fetchBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!kIsWeb) {
        _books = await BookDatabase.instance.readAllBooks();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cari buku dari Open Library API
  Future<void> searchBooksFromApi(String query) async {
    final trimmed = query.trim();
    _lastSearchQuery = trimmed;

    if (trimmed.length < 2) {
      _searchResults = [];
      _searchError = null;
      _isSearching = false;
      _hasSearched = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    _hasSearched = false;
    notifyListeners();

    try {
      final results = await _apiService.searchBooks(trimmed);
      _searchResults = results;
      _searchError = null;
      _hasSearched = true;
    } catch (e) {
      if (!kIsWeb && e is SocketException) {
        _searchResults = [];
        _hasSearched = true;
        _searchError = 'Tidak ada koneksi internet. Periksa jaringan lalu coba lagi.';
      } else if (e is TimeoutException) {
        _searchResults = [];
        _hasSearched = true;
        _searchError =
            'Waktu permintaan habis (timeout). Server merespons terlalu lama. Silakan mengisi data secara manual atau periksa jaringan';
      } else if (e is FormatException) {
        debugPrint("Search Format Error: $e");
        _searchResults = [];
        _hasSearched = true;
        _searchError = 'Data dari server tidak sesuai format yang diharapkan.';
      } else if (!kIsWeb && e is HttpException) {
        debugPrint("Search HTTP Error: $e");
        _searchResults = [];
        _hasSearched = true;
        _searchError = 'Layanan pencarian sedang bermasalah (HTTP error). Silakan coba lagi.';
      } else {
        debugPrint("Search API Error: $e");
        final message = e.toString();
        _searchResults = [];
        _hasSearched = true;
        if (message.contains('404')) {
          _searchError = 'Endpoint pencarian tidak ditemukan (404).';
        } else if (message.contains('422')) {
          _searchError =
              'Format kata kunci pencarian tidak valid (422). Minimal 3 karakter.';
        } else if (message.contains('429')) {
          _searchError = 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.';
        } else if (message.contains('4') || message.contains('5')) {
          _searchError = 'Terjadi gangguan pada server pencarian. Silakan coba lagi.';
        } else {
          _searchError = 'Gagal memuat data buku. Periksa koneksi lalu coba lagi.';
        }
      }
    }

    _isSearching = false;
    notifyListeners();
  }

  // Ulangi pencarian terakhir saat tombol "Coba Lagi" ditekan
  Future<void> retrySearchBooks() async {
    if (_lastSearchQuery.length >= 2) {
      await searchBooksFromApi(_lastSearchQuery);
    }
  }

  // Bersihkan daftar saran pencarian
  void clearSearchResults() {
    _searchResults = [];
    _searchError = null;
    _isSearching = false;
    _hasSearched = false;
    _lastSearchQuery = '';
    notifyListeners();
  }

  // Tambah buku (termasuk foto & referensi Open Library API)
  Future<void> addBook(
    String judul,
    String penulis,
    String kategori,
    String deskripsi,
    String tanggal,
    String status, {
    String? imagePath,
    String? openLibraryKey,
  }) async {
    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      judul: judul,
      penulis: penulis,
      kategori: kategori,
      deskripsi: deskripsi,
      tanggal: tanggal,
      status: status,
      imagePath: imagePath,
      openLibraryKey: openLibraryKey,
    );

    if (kIsWeb) {
      _books = [newBook, ..._books];
      notifyListeners();
      return;
    }

    await BookDatabase.instance.createBook(newBook);
    await fetchBooks();
  }

  // Ubah buku / Update (termasuk foto & referensi Open Library API)
  Future<void> editBook(
    Book book,
    String judul,
    String penulis,
    String kategori,
    String deskripsi,
    String tanggal,
    String status, {
    String? imagePath,
    String? openLibraryKey,
    bool clearImage = false,
  }) async {
    book.judul = judul;
    book.penulis = penulis;
    book.kategori = kategori;
    book.deskripsi = deskripsi;
    book.tanggal = tanggal;
    book.status = status;
    if (clearImage) {
      book.imagePath = null;
    } else if (imagePath != null) {
      book.imagePath = imagePath;
    }
    if (openLibraryKey != null) {
      book.openLibraryKey = openLibraryKey;
    }

    if (kIsWeb) {
      notifyListeners();
      return;
    }

    await BookDatabase.instance.updateBook(book);
    await fetchBooks();
  }

  // Hapus buku (Delete)
  Future<void> removeBook(String id) async {
    if (kIsWeb) {
      _books = _books.where((b) => b.id != id).toList();
      notifyListeners();
      return;
    }

    await BookDatabase.instance.deleteBook(id);
    await fetchBooks();
  }
}