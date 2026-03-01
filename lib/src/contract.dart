import 'package:http/http.dart' as http;
import 'package:zard/zard.dart';
import 'data.dart';

abstract class HttpContract<R, Res extends http.BaseResponse> {
  final String method;
  final String path;
  final Schema<Map<String, dynamic>>? query;
  final Schema<Map<String, dynamic>>? body;
  final Schema<Map<String, dynamic>>? headers;

  HttpContract({
    required this.method,
    required this.path,
    this.query,
    this.body,
    this.headers,
  });
}

class ObjectQuery<R> extends HttpContract<R, ObjectResponse<R>> {
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

class ObjectCommand<R> extends HttpContract<R, ObjectResponse<R>> {
  ObjectCommand({
    String method = 'POST',
    required super.path,
    super.query,
    super.body,
    super.headers,
  }) : super(method: method);
}

class ListCommand<R> extends HttpContract<R, ListResponse<R>> {
  ListCommand({
    String method = 'POST',
    required super.path,
    super.query,
    super.body,
    super.headers,
  }) : super(method: method);
}

class RawCommand<R> extends HttpContract<R, http.StreamedResponse> {
  RawCommand({
    String method = 'POST',
    required super.path,
    super.query,
    super.body,
    super.headers,
  }) : super(method: method);
}
