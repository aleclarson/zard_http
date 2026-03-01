import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'data.dart';
import 'contract.dart';

abstract class ContractClient {
  /// Executes the request. The generic [Res] seamlessly ensures that passing
  /// an `ObjectCommand` returns an `ObjectResponse`, etc.
  Future<Res> request<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract, {
    Map<String, dynamic>? query,
    dynamic body,
    Map<String, String>? headers,
  });
}

class HttpContractClient implements ContractClient {
  final String baseUrl;
  final http.Client _client;

  HttpContractClient(this.baseUrl, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<Res> request<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract, {
    Map<String, dynamic>? query,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    // 1. Pre-flight Validation
    if (contract.query != null && query != null) {
      contract.query!.parse(query);
    }
    if (contract.body != null && body != null) {
      contract.body!.parse(body);
    }
    if (contract.headers != null && headers != null) {
      contract.headers!.parse(headers);
    }

    // 2. Build Request
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

    final request = http.Request(contract.method, uri);
    request.headers.addAll(requestHeaders);
    if (body != null) {
      if (body is Map) {
        request.body = jsonEncode(body);
      } else if (body is Uint8List || body is List<int>) {
        request.bodyBytes = body as List<int>;
      } else {
        request.body = body.toString();
      }
    }

    // 3. Send
    final response = await _client.send(request);

    // 4. Wrap Response
    if (contract is RawQuery<R> ||
        contract is RawCommand<R> ||
        contract is RawUpload<R>) {
      return response as Res;
    }

    if (contract is ObjectQuery<R> ||
        contract is ObjectCommand<R> ||
        contract is ObjectUpload<R>) {
      return ObjectResponse<R>(response) as Res;
    } else if (contract is ListQuery<R> ||
        contract is ListCommand<R> ||
        contract is ListUpload<R>) {
      return ListResponse<R>(response) as Res;
    }

    throw Exception('Unknown contract type: $Res');
  }
}
