import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/app_models.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _getJson(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Błąd backendu: ${response.statusCode}');
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw ApiException('Niepoprawny format odpowiedzi JSON');
  }

  Future<List<dynamic>> _getJsonList(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Błąd backendu: ${response.statusCode}');
    }

    if (response.body.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is List<dynamic>) {
      return decoded;
    }

    throw ApiException('Niepoprawny format listy JSON');
  }

  Future<BookSearchResponse> searchBooks({
    required String query,
    required String currency,
    int page = 0,
    int size = 20,
  }) async {
    final json = await _getJson('/api/v1/books/search', {
      'q': query,
      'page': '$page',
      'size': '$size',
      'currency': currency,
    });
    return BookSearchResponse.fromJson(json);
  }

  Future<BookDetails> getBookDetails({
    required String bookId,
    required String currency,
  }) async {
    final json = await _getJson('/api/v1/books/$bookId', {
      'currency': currency,
    });
    return BookDetails.fromJson(json);
  }

  Future<List<OfferItem>> getBookOffers({
    required String bookId,
    required String currency,
    String sort = 'PRICE_ASC',
    String? source,
  }) async {
    final query = <String, String>{
      'currency': currency,
      'sort': sort,
      if (source != null && source.isNotEmpty) 'source': source,
    };
    final json = await _getJsonList('/api/v1/books/$bookId/offers', query);
    return json.whereType<Map<String, dynamic>>().map(OfferItem.fromJson).toList();
  }

  Future<AuthorSearchResponse> searchAuthors({
    required String query,
    int page = 0,
    int size = 20,
  }) async {
    final json = await _getJson('/api/v1/authors/search', {
      'q': query,
      'page': '$page',
      'size': '$size',
    });
    return AuthorSearchResponse.fromJson(json);
  }

  Future<AuthorDetails> getAuthorDetails({required String authorId}) async {
    final json = await _getJson('/api/v1/authors/$authorId');
    return AuthorDetails.fromJson(json);
  }

  Future<BookSearchResponse> getAuthorBooks({
    required String authorId,
    required String currency,
    int page = 0,
    int size = 20,
  }) async {
    final json = await _getJson('/api/v1/authors/$authorId/books', {
      'page': '$page',
      'size': '$size',
      'currency': currency,
    });
    return BookSearchResponse.fromJson(json);
  }

  Future<CurrencyListResponse> getCurrencies({required String base}) async {
    final json = await _getJson('/api/v1/currencies', {
      'base': base,
    });
    return CurrencyListResponse.fromJson(json);
  }

  Future<CurrencyListResponse> getRates({required String base}) async {
    final json = await _getJson('/api/v1/currencies/rates', {
      'base': base,
    });
    return CurrencyListResponse.fromJson(json);
  }
}
