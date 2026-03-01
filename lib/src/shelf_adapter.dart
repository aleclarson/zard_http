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
    Future<Response> Function(ContractRequest<R>) handler,
  ) {
    add(contract.method, contract.path, (Request shelfRequest) async {
      try {
        final contractRequest = await ContractRequest.fromShelfRequest<R, Res>(shelfRequest, contract);
        return await handler(contractRequest);
      } on ZardError catch (e) {
        return Response(400,
            body: jsonEncode({'errors': e.issues.map((i) => i.message).toList()}),
            headers: {'Content-Type': 'application/json'});
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });
  }

  void addQuery<R, Res extends http.BaseResponse>(
    HttpContract<R, Res> contract,
    Future<Response> Function(ContractRequest<R>) handler,
  ) =>
      addCommand(contract, handler);
}

class ContractRequest<R> {
  final Request shelfRequest;
  final ObjectData<R>? query;
  final ObjectData<R>? body;
  final Map<String, String> headers;

  ContractRequest({
    required this.shelfRequest,
    this.query,
    this.body,
    required this.headers,
  });

  static Future<ContractRequest<R>> fromShelfRequest<R, Res extends http.BaseResponse>(
    Request shelfRequest,
    HttpContract<R, Res> contract,
  ) async {

    // Validate Headers
    final headers = shelfRequest.headers;
    if (contract.headers != null) {
      contract.headers!.parse(headers);
    }

    // Validate Query
    ObjectData<R>? queryData;
    if (contract.query != null) {
      final queryParams = shelfRequest.url.queryParameters;
      final parsedQuery = contract.query!.parse(queryParams);
      queryData = ObjectData<R>(parsedQuery as Map<String, dynamic>);
    }

    // Validate Body
    ObjectData<R>? bodyData;
    if (contract.body != null) {
      final bodyText = await shelfRequest.readAsString();
      final decodedBody = bodyText.isNotEmpty ? jsonDecode(bodyText) : null;
      final parsedBody = contract.body!.parse(decodedBody ?? <String, dynamic>{});
      bodyData = ObjectData<R>(parsedBody as Map<String, dynamic>);
    }

    return ContractRequest<R>(
      shelfRequest: shelfRequest,
      query: queryData,
      body: bodyData,
      headers: headers,
    );
  }
}
