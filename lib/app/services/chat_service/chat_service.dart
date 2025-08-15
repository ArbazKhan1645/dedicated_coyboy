import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';

class AIChatService extends GetxService {
  Future<AIChatService> init() async {
    return this;
  }

  final http.Client _client;
  final String _apiKey;
  final String _baseUrl;
  final List<ChatMessage> _conversationHistory = [];

  AIChatService({
    required String apiKey,
    required String baseUrl,
    http.Client? client,
    String? systemPrompt,
  }) : _client = client ?? http.Client(),
       _apiKey = apiKey,
       _baseUrl = baseUrl {
    if (systemPrompt != null) {
      _conversationHistory.add(
        ChatMessage(role: 'system', content: systemPrompt),
      );
    }
  }

  void dispose() {
    _client.close();
  }

  // Clears conversation history while keeping system prompt if it exists
  void resetConversation() {
    if (_conversationHistory.isNotEmpty &&
        _conversationHistory.first.role == 'system') {
      final systemPrompt = _conversationHistory.first;
      _conversationHistory.clear();
      _conversationHistory.add(systemPrompt);
    } else {
      _conversationHistory.clear();
    }
  }

  // Gets the current conversation history (read-only)
  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  Future<String> sendMessage({
    required String message,
    String? model,
    double temperature = 0.7,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 30),
    Duration retryDelay = const Duration(milliseconds: 500),
    bool rememberContext = true,
  }) async {
    try {
      // Add user message to history
      _conversationHistory.add(ChatMessage(role: 'user', content: message));

      final response = await retry(
        () => _makeRequest(
          messages: _conversationHistory.map((m) => m.toMap()).toList(),
          model: model ?? 'gpt-3.5-turbo',
          temperature: temperature,
        ),
        retryIf: (e) => _shouldRetry(e),
        maxAttempts: maxRetries,
        delayFactor: Duration(milliseconds: retryDelay.inMilliseconds ~/ 2),
      ).timeout(timeout);

      final assistantReply = _parseResponse(response);

      if (rememberContext) {
        // Add assistant reply to history to maintain context
        _conversationHistory.add(
          ChatMessage(role: 'assistant', content: assistantReply),
        );
      }

      return assistantReply;
    } on TimeoutException catch (e, stackTrace) {
      // Remove the user message if the request failed
      if (_conversationHistory.isNotEmpty &&
          _conversationHistory.last.role == 'user') {
        _conversationHistory.removeLast();
      }
      throw ApiException(
        'Request timed out after $timeout',
        stackTrace: stackTrace,
      );
    } on SocketException catch (e, stackTrace) {
      throw ApiException('No internet connection', stackTrace: stackTrace);
    } on http.ClientException catch (e, stackTrace) {
      throw ApiException('Network error: ${e.message}', stackTrace: stackTrace);
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      throw ApiException(
        'Unexpected error: ${e.toString()}',
        stackTrace: stackTrace,
      );
    }
  }

  Future<http.Response> _makeRequest({
    required List<Map<String, String>> messages,
    required String model,
    required double temperature,
  }) async {
    final body = json.encode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
    });

    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final response = await _client.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: headers,
      body: body,
    );

    _validateResponse(response);
    return response;
  }

  String _parseResponse(http.Response response) {
    final jsonResponse = json.decode(response.body);

    if (jsonResponse['choices'] == null || jsonResponse['choices'].isEmpty) {
      throw ApiException('No response choices from the API');
    }

    final message = jsonResponse['choices'][0]['message'];
    if (message == null) {
      throw ApiException('No message in the response');
    }

    final content = message['content'];
    if (content == null) {
      throw ApiException('No content in the response message');
    }

    return content.toString().trim();
  }

  void _validateResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body;

    switch (statusCode) {
      case 200:
        return;
      case 400:
        throw ApiException(
          'Invalid request parameters',
          statusCode: statusCode,
          response: responseBody,
        );
      case 401:
        throw ApiException(
          'Unauthorized - Invalid or missing API key',
          statusCode: statusCode,
        );
      case 403:
        throw ApiException(
          'Forbidden - Insufficient permissions',
          statusCode: statusCode,
        );
      case 404:
        throw ApiException(
          'Endpoint not found - Verify the API URL',
          statusCode: statusCode,
        );
      case 429:
        throw ApiException(
          'Rate limit exceeded - Please wait before making new requests',
          statusCode: statusCode,
        );
      case 500:
        throw ApiException(
          'Internal server error',
          statusCode: statusCode,
          response: responseBody,
        );
      case 502:
      case 503:
      case 504:
        throw ApiException(
          'Service temporarily unavailable',
          statusCode: statusCode,
        );
      default:
        throw ApiException(
          'Unexpected HTTP status: $statusCode',
          statusCode: statusCode,
          response: responseBody,
        );
    }
  }

  bool _shouldRetry(Exception e) {
    if (e is ApiException) {
      return e.statusCode != null &&
          (e.statusCode! >= 500 || e.statusCode == 429);
    }
    return e is SocketException || e is TimeoutException;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;
  final StackTrace? stackTrace;

  ApiException(this.message, {this.statusCode, this.response, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) buffer.write(' (Status: $statusCode)');
    if (response != null) buffer.write('\nResponse: $response');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    return buffer.toString();
  }
}

class ChatMessage {
  final String role; // 'system', 'user', or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, String> toMap() => {'role': role, 'content': content};
}
