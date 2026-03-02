import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zard/zard.dart';
import 'contract.dart';
import 'data.dart';

extension ContractRouter on Router {
  void addCommand<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract,
    Future<Response> Function(CommandRequest<R>) handler,
  ) {
    if (contract is! HttpCommand<R>) {
      throw ArgumentError.value(
        contract,
        'contract',
        'addCommand expects an HttpCommand contract.',
      );
    }

    add(contract.method, contract.path, (Request shelfRequest) async {
      try {
        final contractRequest =
            await ShelfCommandRequest.fromShelfRequest<R, Res>(
                shelfRequest, contract);
        return await handler(contractRequest);
      } on ZardError catch (e) {
        return Response(400,
            body:
                jsonEncode({'errors': e.issues.map((i) => i.message).toList()}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });
  }

  void addQuery<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract,
    Future<Response> Function(QueryRequest<R>) handler,
  ) {
    if (contract is! HttpQuery<R>) {
      throw ArgumentError.value(
        contract,
        'contract',
        'addQuery expects an HttpQuery contract.',
      );
    }

    add(contract.method, contract.path, (Request shelfRequest) async {
      try {
        final contractRequest =
            await ShelfQueryRequest.fromShelfRequest<R, Res>(
                shelfRequest, contract);
        return await handler(contractRequest);
      } on ZardError catch (e) {
        return Response(400,
            body:
                jsonEncode({'errors': e.issues.map((i) => i.message).toList()}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });
  }

  void addUpload<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract,
    Future<Response> Function(UploadRequest<R>) handler,
  ) {
    if (contract is! HttpUpload<R>) {
      throw ArgumentError.value(
        contract,
        'contract',
        'addUpload expects an HttpUpload contract.',
      );
    }

    add(contract.method, contract.path, (Request shelfRequest) async {
      try {
        final contractRequest =
            await ShelfUploadRequest.fromShelfRequest<R, Res>(
                shelfRequest, contract);
        return await handler(contractRequest);
      } on ZardError catch (e) {
        return Response(400,
            body:
                jsonEncode({'errors': e.issues.map((i) => i.message).toList()}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });
  }
}

class ShelfQueryRequest<R> implements QueryRequest<R> {
  final Request shelfRequest;
  @override
  final DataMap<R>? query;
  @override
  final Map<String, String> headers;

  ShelfQueryRequest({
    required this.shelfRequest,
    this.query,
    required this.headers,
  });

  static Future<ShelfQueryRequest<R>>
      fromShelfRequest<R, Res extends http.BaseResponse>(
    Request shelfRequest,
    HttpContract<R, Res> contract,
  ) async {
    // Validate Headers
    final headers = shelfRequest.headers;
    if (contract.headers != null) {
      contract.headers!.parse(headers);
    }

    // Validate Query
    DataMap<R>? queryData;
    if (contract.query != null) {
      final queryParams = shelfRequest.url.queryParameters;
      final parsedQuery = contract.query!.parse(queryParams);
      queryData = DataMap<R>(parsedQuery);
    }

    return ShelfQueryRequest<R>(
      shelfRequest: shelfRequest,
      query: queryData,
      headers: headers,
    );
  }
}

class ShelfCommandRequest<R> implements CommandRequest<R> {
  final Request shelfRequest;
  @override
  final DataMap<R>? query;
  @override
  final Map<String, String> headers;
  @override
  final DataMap<R> body;

  ShelfCommandRequest({
    required this.shelfRequest,
    this.query,
    required this.headers,
    required this.body,
  });

  static Future<ShelfCommandRequest<R>>
      fromShelfRequest<R, Res extends http.BaseResponse>(
    Request shelfRequest,
    HttpContract<R, Res> contract,
  ) async {
    // Validate Headers
    final headers = shelfRequest.headers;
    if (contract.headers != null) {
      contract.headers!.parse(headers);
    }

    // Validate Query
    DataMap<R>? queryData;
    if (contract.query != null) {
      final queryParams = shelfRequest.url.queryParameters;
      final parsedQuery = contract.query!.parse(queryParams);
      queryData = DataMap<R>(parsedQuery);
    }

    // Validate Body
    final bodyText = await shelfRequest.readAsString();
    final decodedBody = bodyText.isNotEmpty ? jsonDecode(bodyText) : null;
    final parsedBody = contract.body!.parse(decodedBody ?? <String, dynamic>{});
    final bodyData = DataMap<R>(parsedBody as Map<String, dynamic>);

    return ShelfCommandRequest<R>(
      shelfRequest: shelfRequest,
      query: queryData,
      headers: headers,
      body: bodyData,
    );
  }
}

class ShelfUploadRequest<R> implements UploadRequest<R> {
  final Request shelfRequest;
  @override
  final DataMap<R>? query;
  @override
  final Map<String, String> headers;

  ShelfUploadRequest({
    required this.shelfRequest,
    this.query,
    required this.headers,
  });

  @override
  Stream<List<int>> read() => shelfRequest.read();

  static Future<ShelfUploadRequest<R>>
      fromShelfRequest<R, Res extends http.BaseResponse>(
    Request shelfRequest,
    HttpContract<R, Res> contract,
  ) async {
    // Validate Headers
    final headers = shelfRequest.headers;
    if (contract.headers != null) {
      contract.headers!.parse(headers);
    }

    // Validate Query
    DataMap<R>? queryData;
    if (contract.query != null) {
      final queryParams = shelfRequest.url.queryParameters;
      final parsedQuery = contract.query!.parse(queryParams);
      queryData = DataMap<R>(parsedQuery);
    }

    return ShelfUploadRequest<R>(
      shelfRequest: shelfRequest,
      query: queryData,
      headers: headers,
    );
  }
}
