import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'data.dart';
import 'contract.dart';

abstract class ContractClient {
  /// Executes the request. The generic [Res] seamlessly ensures that passing
  /// a contract with `.returnsMap()` returns a `MapResponse`, etc.
  Future<Res> request<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract, {
    Map<String, dynamic>? query,
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Releases any resources held by the underlying transport client.
  void close();
}

/// A policy that determines if a request should be retried after an error.
typedef RetryStrategy = Future<bool> Function(int attempt, Object error);

class HttpContractClient implements ContractClient {
  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;
  final Duration? defaultTimeout;
  final RetryStrategy? retryStrategy;

  HttpContractClient(
    this.baseUrl, {
    http.Client? client,
    this.defaultTimeout,
    this.retryStrategy,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  @override
  Future<Res> request<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract, {
    Map<String, dynamic>? query,
    dynamic body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    // 1. Pre-flight Validation
    if (contract.body != null && body == null) {
      throw ArgumentError('A non-null body is required for this contract.');
    }

    if (contract.query != null && query != null) {
      contract.query!.parse(query);
    }
    if (contract.body != null && body != null) {
      contract.body!.parse(body);
    }
    if (contract.headers != null && headers != null) {
      contract.headers!.parse(headers);
    }

    // 2. Build URI
    final fullPath = baseUrl.endsWith('/') && contract.path.startsWith('/')
        ? baseUrl + contract.path.substring(1)
        : !baseUrl.endsWith('/') && !contract.path.startsWith('/')
            ? '$baseUrl/${contract.path}'
            : baseUrl + contract.path;

    final uri = Uri.parse(fullPath).replace(
      queryParameters:
          query?.map((key, value) => MapEntry(key, value.toString())),
    );

    final requestHeaders = {
      if (body is Map) 'Content-Type': 'application/json',
      ...?headers,
    };

    http.Request buildRequest() {
      final req = http.Request(contract.method, uri);
      req.headers.addAll(requestHeaders);
      if (body != null) {
        if (body is Map) {
          req.body = jsonEncode(body);
        } else if (body is Uint8List || body is List<int>) {
          req.bodyBytes = body as List<int>;
        } else {
          req.body = body.toString();
        }
      }
      return req;
    }

    // 3. Send with Retries and Timeout
    final effectiveTimeout = timeout ?? defaultTimeout;
    int attempt = 0;
    http.StreamedResponse? response;

    while (true) {
      attempt++;
      try {
        final req = buildRequest();
        var future = _client.send(req);

        if (effectiveTimeout != null) {
          future = future.timeout(effectiveTimeout);
        }

        response = await future;
        break; // Success, exit retry loop
      } catch (e) {
        if (retryStrategy != null && await retryStrategy!(attempt, e)) {
          continue;
        }
        rethrow;
      }
    }

    // 4. Wrap Response
    if (contract is HttpContract<R, MapResponse<R>>) {
      return MapResponse<R>(response) as Res;
    } else if (contract is HttpContract<R, ListResponse<R>>) {
      return ListResponse<R>(response) as Res;
    } else if (contract is HttpContract<R, VoidResponse<R>>) {
      return VoidResponse<R>(response) as Res;
    } else if (contract is HttpContract<R, http.StreamedResponse>) {
      return response as Res;
    }

    throw Exception('Unknown contract type: $Res');
  }

  @override
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
