import 'package:zard/zard.dart';
import 'package:zard/src/zard_base.dart';
import 'data.dart';

extension ZardObjectExtension on Zard {
  ZMap object(Map<String, Schema> schema, {String? message}) => map(schema, message: message);
  ZList array(Schema itemSchema, {String? message}) => list(itemSchema, message: message);
}

abstract class HttpContract<R, Res extends BaseResponse<R>> {
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
