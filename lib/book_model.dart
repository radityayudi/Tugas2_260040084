class Book {
  final String id;
  String judul;
  String penulis;
  String kategori;
  String deskripsi;
  String tanggal;
  String status;
  String? imagePath;
  String? openLibraryKey;

  Book({
    required this.id,
    required this.judul,
    this.penulis = '',
    required this.kategori,
    this.deskripsi = '',
    required this.tanggal,
    required this.status,
    this.imagePath,
    this.openLibraryKey,
  });

  // Mengubah objek Book menjadi Map (untuk disimpan ke database SQLite)
  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'penulis': penulis,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'tanggal': tanggal,
        'status': status,
        'imagePath': imagePath,
        'openLibraryKey': openLibraryKey,
      };

  // Mengubah Map kembali menjadi objek Book (saat dibaca dari database SQLite)
  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id']?.toString() ?? '',
        judul: json['judul']?.toString() ?? '',
        penulis: json['penulis']?.toString() ?? '',
        kategori: json['kategori']?.toString() ?? '',
        deskripsi: json['deskripsi']?.toString() ?? '',
        tanggal: json['tanggal']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Tersedia',
        imagePath: json['imagePath']?.toString(),
        openLibraryKey: json['openLibraryKey']?.toString(),
      );
}