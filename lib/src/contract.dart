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

class ObjectQuery<R> extends HttpContract<R, MapResponse<R>> {
  ObjectQuery({
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

class RawQuery<R> extends HttpContract<R, http.StreamedResponse> {
  RawQuery({
    required super.path,
    super.query,
    super.headers,
  }) : super(method: 'GET');
}

class ObjectCommand<R> extends HttpContract<R, MapResponse<R>> {
  ObjectCommand({
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

class RawCommand<R> extends HttpContract<R, http.StreamedResponse> {
  RawCommand({
    String method = 'POST',
    required super.path,
    required Schema<Map<String, dynamic>> body,
    super.query,
    super.headers,
  }) : super(method: method, body: body);
}

class ObjectUpload<R> extends HttpContract<R, MapResponse<R>> {
  ObjectUpload({
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

class RawUpload<R> extends HttpContract<R, http.StreamedResponse> {
  RawUpload({
    String method = 'POST',
    required super.path,
    super.query,
    super.headers,
  }) : super(method: method);
}
