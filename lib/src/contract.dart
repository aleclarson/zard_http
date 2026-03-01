import 'package:http/http.dart' as http;
import 'package:zard/zard.dart';
import 'data.dart';

class HttpContract<R, Res extends http.BaseResponse> {
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

typedef MapQuery<R> = HttpContract<R, MapResponse<R>>;
typedef ListQuery<R> = HttpContract<R, ListResponse<R>>;
typedef VoidQuery<R> = HttpContract<R, VoidResponse<R>>;

class HttpQuery<R> extends HttpContract<R, http.StreamedResponse> {
  HttpQuery({
    required super.path,
    super.query,
    super.headers,
  }) : super(method: 'GET');

  MapQuery<R> returnsMap() => this as MapQuery<R>;
  ListQuery<R> returnsList() => this as ListQuery<R>;
  VoidQuery<R> returnsVoid() => this as VoidQuery<R>;
}

typedef MapCommand<R> = HttpContract<R, MapResponse<R>>;
typedef ListCommand<R> = HttpContract<R, ListResponse<R>>;
typedef VoidCommand<R> = HttpContract<R, VoidResponse<R>>;

class HttpCommand<R> extends HttpContract<R, http.StreamedResponse> {
  HttpCommand({
    String method = 'POST',
    required super.path,
    required Schema<Map<String, dynamic>> body,
    super.query,
    super.headers,
  }) : super(method: method, body: body);

  MapCommand<R> returnsMap() => this as MapCommand<R>;
  ListCommand<R> returnsList() => this as ListCommand<R>;
  VoidCommand<R> returnsVoid() => this as VoidCommand<R>;
}

typedef MapUpload<R> = HttpContract<R, MapResponse<R>>;
typedef ListUpload<R> = HttpContract<R, ListResponse<R>>;
typedef VoidUpload<R> = HttpContract<R, VoidResponse<R>>;

class HttpUpload<R> extends HttpContract<R, http.StreamedResponse> {
  HttpUpload({
    String method = 'POST',
    required super.path,
    super.query,
    super.headers,
  }) : super(method: method);

  MapUpload<R> returnsMap() => this as MapUpload<R>;
  ListUpload<R> returnsList() => this as ListUpload<R>;
  VoidUpload<R> returnsVoid() => this as VoidUpload<R>;
}
