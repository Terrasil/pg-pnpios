import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/app_models.dart';

class ApiException implements Exception {
  final ApiErrorResponse error;

  const ApiException(this.error);

  @override
  String toString() {
    if (error.details.isEmpty) {
      return '${error.status} ${error.error}: ${error.message}';
    }
    return '${error.status} ${error.error}: ${error.message} | ${error.details.join(', ')}';
  }
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _jsonHeaders => const {'Accept': 'application/json'};

  Map<String, String> get _jsonHeadersWithBody => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final rawBase = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final filtered = <String, String>{};
    query?.forEach((key, value) {
      if (value.trim().isNotEmpty) {
        filtered[key] = value;
      }
    });
    return Uri.parse('$rawBase$path').replace(queryParameters: filtered.isEmpty ? null : filtered);
  }

  ApiErrorResponse _parseError(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return ApiErrorResponse.fromJson(decoded);
      }
    } catch (_) {}
    return ApiErrorResponse(
      timestamp: null,
      status: response.statusCode,
      error: 'Error',
      message: response.body.isEmpty ? 'Unknown error' : utf8.decode(response.bodyBytes),
      path: null,
      details: const [],
    );
  }

  Future<Map<String, dynamic>> _getJson(String path, [Map<String, String>? query]) async {
    final response = await _client
        .get(_buildUri(path, query), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_parseError(response));
    }
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ApiException(ApiErrorResponse(
      timestamp: null,
      status: 500,
      error: 'Invalid JSON',
      message: 'Niepoprawny format odpowiedzi JSON',
      path: null,
      details: [],
    ));
  }

  Future<List<dynamic>> _getJsonList(String path, [Map<String, String>? query]) async {
    final response = await _client
        .get(_buildUri(path, query), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_parseError(response));
    }
    if (response.body.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw const ApiException(ApiErrorResponse(
      timestamp: null,
      status: 500,
      error: 'Invalid JSON',
      message: 'Niepoprawny format listy JSON',
      path: null,
      details: [],
    ));
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
    final json = await _getJson('/api/v1/books/$bookId', {'currency': currency});
    return BookDetails.fromJson(json);
  }

  Future<List<OfferItem>> getBookOffers({
    required String bookId,
    required String currency,
    OfferSortType sort = OfferSortType.priceAsc,
    String? source,
  }) async {
    final json = await _getJsonList('/api/v1/books/$bookId/offers', {
      'currency': currency,
      'sort': sort.apiValue,
      if (source != null && source.isNotEmpty) 'source': source,
    });
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

  Future<AuthorDetails> getAuthorDetails({
    required String authorId,
    String currency = 'PLN',
  }) async {
    final json = await _getJson('/api/v1/authors/$authorId', {'currency': currency});
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
    final json = await _getJson('/api/v1/currencies', {'base': base});
    return CurrencyListResponse.fromJson(json);
  }

  Future<CurrencyListResponse> getRates({required String base}) async {
    final json = await _getJson('/api/v1/currencies/rates', {'base': base});
    return CurrencyListResponse.fromJson(json);
  }

  Future<CurrencyConversionResult> convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) async {
    final response = await _client
        .post(
          _buildUri('/api/v1/currencies/convert'),
          headers: _jsonHeadersWithBody,
          body: jsonEncode(CurrencyConvertRequest(amount: amount, from: from, to: to).toJson()),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_parseError(response));
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return CurrencyConversionResult.fromJson(decoded);
    }
    throw const ApiException(ApiErrorResponse(
      timestamp: null,
      status: 500,
      error: 'Invalid JSON',
      message: 'Niepoprawny format odpowiedzi JSON',
      path: null,
      details: [],
    ));
  }
}
