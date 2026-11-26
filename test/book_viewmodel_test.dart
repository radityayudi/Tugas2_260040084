import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_buku/book_api_service.dart';
import 'package:katalog_buku/book_viewmodel.dart';

class _FakeBookApiService extends BookApiService {
  final Future<List<BookSearchSuggestion>> Function(String query, {int limit})
      onSearchBooks;

  _FakeBookApiService(this.onSearchBooks);

  @override
  Future<List<BookSearchSuggestion>> searchBooks(
    String query, {
    int limit = 8,
  }) {
    return onSearchBooks(query, limit: limit);
  }
}

void main() {
  test('ViewModel mengisi searchResults dari service palsu', () async {
    final fakeApi = _FakeBookApiService((query, {int limit = 8}) async {
      return [
        BookSearchSuggestion(
          openLibraryKey: '/works/OL123W',
          title: 'Clean Architecture',
          author: 'Robert C. Martin',
          category: 'Software Engineering',
          description: 'Panduan arsitektur perangkat lunak.',
        ),
      ];
    });

    final viewModel = BookViewModel(apiService: fakeApi);

    await viewModel.searchBooksFromApi('Clean');

    expect(viewModel.searchError, isNull);
    expect(viewModel.hasSearched, isTrue);
    expect(viewModel.searchResults.length, 1);
    expect(viewModel.searchResults.first.title, 'Clean Architecture');
  });

  test('ViewModel mengisi pesan error 422 saat service palsu melempar 422', () async {
    final fakeApi = _FakeBookApiService((query, {int limit = 8}) async {
      throw Exception('HTTP 422: format kata kunci tidak valid');
    });

    final viewModel = BookViewModel(apiService: fakeApi);

    await viewModel.searchBooksFromApi('ab');

    expect(viewModel.searchResults, isEmpty);
    expect(viewModel.hasSearched, isTrue);
    expect(viewModel.searchError, contains('422'));
  });
}