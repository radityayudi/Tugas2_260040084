import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'book_model.dart';

class BookDatabase {
  static final BookDatabase instance = BookDatabase._init();
  static Database? _database;

  BookDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('books.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        judul TEXT NOT NULL,
        penulis TEXT NOT NULL DEFAULT '',
        kategori TEXT NOT NULL,
        deskripsi TEXT NOT NULL DEFAULT '',
        tanggal TEXT NOT NULL,
        status TEXT NOT NULL,
        imagePath TEXT,
        openLibraryKey TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE books ADD COLUMN penulis TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE books ADD COLUMN deskripsi TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE books ADD COLUMN imagePath TEXT');
      await db.execute('ALTER TABLE books ADD COLUMN openLibraryKey TEXT');
    }
  }

  // 1. CREATE: Menambah data buku baru
  Future<int> createBook(Book book) async {
    final db = await instance.database;
    return await db.insert('books', book.toJson());
  }

  // 2. READ: Mengambil seluruh data buku
  Future<List<Book>> readAllBooks() async {
    final db = await instance.database;
    final result = await db.query('books', orderBy: 'judul ASC');
    return result.map((json) => Book.fromJson(json)).toList();
  }

  // 3. UPDATE: Mengubah data buku
  Future<int> updateBook(Book book) async {
    final db = await instance.database;
    return await db.update(
      'books',
      book.toJson(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  // 4. DELETE: Menghapus data buku berdasarkan ID
  Future<int> deleteBook(String id) async {
    final db = await instance.database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}