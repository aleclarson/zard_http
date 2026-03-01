import 'package:http/http.dart' as http;
import 'package:zard/zard.dart';
import 'data.dart';

abstract class HttpContract<R, Res extends http.BaseResponse> {
  final String method;
  final String path;
  final Schema<Map<String, dynamic>>? query;
  final Schema<dynamic>? body;
  final Schema<Map<String, dynamic>>? headers;

  HttpContract({
    required this.method,
    required this.path,
    this.query,
    this.body,
    this.headers,
  });
}

class HttpQuery<R> extends HttpContract<R, http.StreamedResponse> {
  HttpQuery({
    required super.path,
    super.query,
    super.headers,
  }) : super(method: 'GET');

  MapQuery<R> returnsMap() => MapQuery<R>(
        path: path,
        query: query,
        headers: headers,
      );

  ListQuery<R> returnsList() => ListQuery<R>(
        path: path,
        query: query,
        headers: headers,
      );

  VoidQuery<R> returnsVoid() => VoidQuery<R>(
        path: path,
        query: query,
        headers: headers,
      );
}

class MapQuery<R> extends HttpContract<R, MapResponse<R>> {
  MapQuery({
    required super.path,
    super.query,
    super.headers,
  }) : super(method: 'GET');
}

class ListQuery<R> extends HttpContract<R, ListResponse<R>> {
  ListQuery({
    required super.path,
    super.query,
    super.headers,
  }) : super(method: 'GET');
}

class VoidQuery<R> extends HttpContract<R, VoidResponse<R>> {
  VoidQuery({
    required super.path,
    super.query,
    super.headers,
  }) : super(method: 'GET');
}

class HttpCommand<R> extends HttpContract<R, http.StreamedResponse> {
  HttpCommand({
    String method = 'POST',
    required super.path,
    required Schema<Map<String, dynamic>> body,
    super.query,
    super.headers,
  }) : super(method: method, body: body);

  MapCommand<R> returnsMap() => MapCommand<R>(
        method: method,
        path: path,
        body: body as Schema<Map<String, dynamic>>,
        query: query,
        headers: headers,
      );

  ListCommand<R> returnsList() => ListCommand<R>(
        method: method,
        path: path,
        body: body as Schema<Map<String, dynamic>>,
        query: query,
        headers: headers,
      );

  VoidCommand<R> returnsVoid() => VoidCommand<R>(
        method: method,
        path: path,
        body: body as Schema<Map<String, dynamic>>,
        query: query,
        headers: headers,
      );
}

class MapCommand<R> extends HttpContract<R, MapResponse<R>> {
  MapCommand({
    String method = 'POST',
    required super.path,
    required Schema<Map<String, dynamic>> body,
    super.query,
    super.headers,
  }) : super(method: method, body: body);
}

class ListCommand<R> extends HttpContract<R, ListResponse<R>> {
  ListCommand({
    String method = 'POST',
    required super.path,
    required Schema<Map<String, dynamic>> body,
    super.query,
    super.headers,
  }) : super(method: method, body: body);
}

class VoidCommand<R> extends HttpContract<R, VoidResponse<R>> {
  VoidCommand({
    String method = 'POST',
    required super.path,
    required Schema<Map<String, dynamic>> body,
    super.query,
    super.headers,
  }) : super(method: method, body: body);
}

class HttpUpload<R> extends HttpContract<R, http.StreamedResponse> {
  HttpUpload({
    String method = 'POST',
    required super.path,
    super.query,
    super.headers,
  }) : super(method: method);

  MapUpload<R> returnsMap() => MapUpload<R>(
        method: method,
        path: path,
        query: query,
        headers: headers,
      );

  ListUpload<R> returnsList() => ListUpload<R>(
        method: method,
        path: path,
        query: query,
        headers: headers,
      );

  VoidUpload<R> returnsVoid() => VoidUpload<R>(
        method: method,
        path: path,
        query: query,
        headers: headers,
      );
}

class MapUpload<R> extends HttpContract<R, MapResponse<R>> {
  MapUpload({
    String method = 'POST',
    required super.path,
    super.query,
    super.headers,
  }) : super(method: method);
}

class ListUpload<R> extends HttpContract<R, ListResponse<R>> {
  ListUpload({
    String method = 'POST',
    required super.path,
    super.query,
    super.headers,
  }) : super(method: method);
}

class VoidUpload<R> extends HttpContract<R, VoidResponse<R>> {
  VoidUpload({
    String method = 'POST',
    required super.path,
    super.query,
    super.headers,
  }) : super(method: method);
}
