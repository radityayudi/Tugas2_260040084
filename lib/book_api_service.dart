import 'dart:convert';
import 'package:http/http.dart' as http;

class BookSearchSuggestion {
  final String title;
  final String author;
  final String? category;
  final String? description;
  final String? openLibraryKey;

  const BookSearchSuggestion({
    required this.title,
    required this.author,
    this.category,
    this.description,
    this.openLibraryKey,
  });

  static const List<String> _preferredGenres = [
    'science fiction',
    'fantasy',
    'historical fiction',
    'fiction',
    'nonfiction',
    'biography',
    'history',
    'mystery',
    'thriller',
    'romance',
    'horror',
    'philosophy',
    'psychology',
    'business',
    'economics',
    'computer science',
    'programming',
    'poetry',
  ];

  static const Set<String> _englishMarkers = {
    'the',
    'and',
    'of',
    'to',
    'for',
    'with',
    'from',
    'by',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'has',
    'have',
    'had',
    'it',
    'this',
    'that',
    'he',
    'she',
    'they',
    'we',
    'you',
    'his',
    'her',
    'their',
    'not',
    'but',
    'or',
    'an',
  };

  static const Set<String> _indonesianMarkers = {
    'yang',
    'dan',
    'di',
    'ke',
    'dari',
    'untuk',
    'ini',
    'itu',
    'adalah',
    'dengan',
    'pada',
    'tidak',
    'bisa',
    'atau',
    'sebuah',
    'suatu',
    'mereka',
    'kami',
    'kita',
    'saya',
    'dia',
    'ia',
    'akan',
    'telah',
    'sudah',
    'oleh',
    'dalam',
    'sebagai',
    'saat',
  };

  static const Set<String> _otherLanguageMarkers = {
    'el',
    'la',
    'los',
    'las',
    'del',
    'una',
    'por',
    'para',
    'con',
    'que',
    'le',
    'les',
    'des',
    'du',
    'une',
    'dans',
    'sur',
    'avec',
    'est',
    'der',
    'die',
    'das',
    'und',
    'ist',
    'nicht',
    'ein',
    'eine',
  };

  factory BookSearchSuggestion.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final title = rawTitle is String && rawTitle.trim().isNotEmpty
        ? rawTitle.trim()
        : 'Judul Tidak Diketahui';

    String author = 'Penulis Tidak Diketahui';
    final rawAuthors = json['author_name'];
    if (rawAuthors is List && rawAuthors.isNotEmpty) {
      final List<String> names = [];
      for (final item in rawAuthors) {
        if (item is String && item.trim().isNotEmpty) {
          names.add(item.trim());
          if (names.length == 2) break;
        }
      }
      if (names.isNotEmpty) {
        author = names.join(', ');
      }
    }

    String? category;
    final rawSubjects = json['subject_facet'] ?? json['subject'];
    if (rawSubjects is List && rawSubjects.isNotEmpty) {
      final validSubjects = <String>[];
      for (final item in rawSubjects) {
        if (item is String) {
          final trimmed = item.trim();
          if (_isValidSubject(trimmed)) {
            validSubjects.add(trimmed);
          }
        }
      }

      if (validSubjects.isNotEmpty) {
        for (final genre in _preferredGenres) {
          String? match;
          for (final subj in validSubjects) {
            if (subj.toLowerCase().contains(genre)) {
              match = subj;
              break;
            }
          }
          if (match != null) {
            category = match;
            break;
          }
        }

        category ??= validSubjects.first;
      }
    }

    String? description;
    final rawFirstSentence = json['first_sentence'];
    String? candidateDescription;

    if (rawFirstSentence is List && rawFirstSentence.isNotEmpty) {
      final first = rawFirstSentence.first;
      if (first is String && first.trim().isNotEmpty) {
        candidateDescription = first.trim();
      }
    } else if (rawFirstSentence is String && rawFirstSentence.trim().isNotEmpty) {
      candidateDescription = rawFirstSentence.trim();
    }

    if (candidateDescription != null &&
        _isEnglishOrIndonesianText(candidateDescription)) {
      description = candidateDescription;
    }

    final rawKey = json['key'];
    final key = rawKey is String ? rawKey : null;

    return BookSearchSuggestion(
      title: title,
      author: author,
      category: category,
      description: description,
      openLibraryKey: key,
    );
  }

  static bool _isValidSubject(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    // Skip URLs
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.')) {
      return false;
    }

    // Skip internal metadata tags (e.g., "nyt:...", "t:...=2022-09-11", "protected_daisy")
    if (trimmed.contains(':') || trimmed.contains('=') || trimmed.contains('_')) {
      return false;
    }

    return true;
  }

  static bool _isEnglishOrIndonesianText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // Reject non-ASCII characters (accents, umlauts, CJK, Cyrillic, Arabic, etc.)
    if (RegExp(r'[^\x00-\x7F]').hasMatch(trimmed)) {
      return false;
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(trimmed)) return false;

    final words = RegExp(r"[a-z']+")
        .allMatches(trimmed.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();

    if (words.isEmpty) return false;

    // Reject if clearly another language
    if (words.any((w) => _otherLanguageMarkers.contains(w))) {
      return false;
    }

    final englishCount = words.where((w) => _englishMarkers.contains(w)).length;
    final indonesianCount =
        words.where((w) => _indonesianMarkers.contains(w)).length;
    final maxMarkerCount =
        englishCount > indonesianCount ? englishCount : indonesianCount;

    if (words.length >= 6) {
      return maxMarkerCount >= 2;
    }
    return maxMarkerCount >= 1;
  }
}

class BookApiService {
  final http.Client _client;

  BookApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<BookSearchSuggestion>> searchBooks(
    String query, {
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return [];
    }

    final uri = Uri.https(
      'openlibrary.org',
      '/search.json',
      {
        'q': trimmed,
        'limit': limit.toString(),
        'fields': 'key,title,author_name,subject,subject_facet,first_sentence',
      },
    );

    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'BookCatalogApp/1.0 (radityayudi@gmail.com)',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data buku (status: ${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons API tidak sesuai');
    }

    final dynamic docs = decoded['docs'];
    if (docs is! List) {
      return [];
    }

    final List<BookSearchSuggestion> suggestions = [];
    for (final doc in docs) {
      if (doc is Map<String, dynamic>) {
        suggestions.add(BookSearchSuggestion.fromJson(doc));
      }
    }
    return suggestions;
  }
}