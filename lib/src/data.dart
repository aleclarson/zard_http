import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:zard/zard.dart';

/// Model-less data accessor.
/// Shared by the server's incoming request bodies/queries, and the client's outgoing responses.
extension type DataMap<R>(Map<String, dynamic> _data) {
  /// Strictly extracts a value of type [T]. Throws if missing or wrong type.
  T get<T>(String key) {
    final value = _data[key];
    if (value == null && !_data.containsKey(key)) {
      throw Exception('Key "$key" not found in data');
    }
    if (value is! T) {
      throw Exception(
          'Value for key "$key" is not of type $T (actual type: ${value.runtimeType})');
    }
    return value;
  }

  /// Extracts an optional value of type [T]. Returns null if missing.
  T? getOptional<T>(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is! T) {
      throw Exception(
          'Value for key "$key" is not of type $T (actual type: ${value.runtimeType})');
    }
    return value;
  }

  /// Parses complex data using a custom [parser] function.
  T parse<T, RAW>(String key, T Function(RAW) parser) {
    final value = get<RAW>(key);
    return parser(value);
  }

  /// Parses complex data using a [Schema].
  T parseBySchema<T, RAW>(String key, Schema<T> schema) =>
      parse<T, RAW>(key, schema.parse);

  /// Parses complex data using a [Schema]. Returns null if the key is missing.
  T? parseBySchemaOptional<T, RAW>(String key, Schema<T> schema) {
    final value = getOptional<RAW>(key);
    return value != null ? schema.parse(value) : null;
  }

  /// Parses an enum by its name.
  T parseEnumByName<T extends Enum>(String key, List<T> values) =>
      parse<T, String>(key, (name) => values.byName(name));

  /// Parses an enum by its name. Returns null if the key is missing.
  T? parseEnumByNameOptional<T extends Enum>(String key, List<T> values) {
    final name = getOptional<String>(key);
    return name != null ? values.byName(name) : null;
  }

  /// Parses a [DateTime] from a string (ISO 8601) or an integer (epoch milliseconds).
  DateTime parseDateTime(String key) => parse<DateTime, Object>(key, (value) {
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        if (value is String) {
          return DateTime.parse(value);
        }
        throw Exception(
            'Value for key "$key" is not a valid DateTime (actual type: ${value.runtimeType})');
      });

  /// Parses a [DateTime] from a string or an integer. Returns null if the key is missing.
  DateTime? parseDateTimeOptional(String key) {
    final value = getOptional<Object>(key);
    if (value == null) return null;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw Exception(
        'Value for key "$key" is not a valid DateTime (actual type: ${value.runtimeType})');
  }
}

extension ByteStreamExtension on Stream<List<int>> {
  /// Consumes the stream and returns a [Uint8List].
  Future<Uint8List> toBytes() async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in this) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}

/// Model-less data accessor for queries.
abstract class QueryRequest<R> {
  DataMap<R>? get query;
  Map<String, String> get headers;
}

/// Model-less data accessor for commands.
abstract class CommandRequest<R> extends QueryRequest<R> {
  @override
  DataMap<R>? get query;
  @override
  Map<String, String> get headers;
  DataMap<R> get body;
}

/// Data accessor for byte-based uploads.
abstract class UploadRequest<R> extends QueryRequest<R> {
  @override
  DataMap<R>? get query;
  @override
  Map<String, String> get headers;
  Stream<List<int>> read();
}

/// Zero-copy extension type for [http.StreamedResponse] to add model-less extraction.
extension type MapResponse<R>(http.StreamedResponse _response)
    implements http.BaseResponse {
  Future<DataMap<R>> json() async {
    final body = await _response.stream.bytesToString();
    return DataMap<R>(jsonDecode(body) as Map<String, dynamic>);
  }
}

/// Zero-copy extension type for [http.StreamedResponse] to add model-less extraction for lists.
extension type ListResponse<R>(http.StreamedResponse _response)
    implements http.BaseResponse {
  Future<List<DataMap<R>>> json() async {
    final body = await _response.stream.bytesToString();
    return (jsonDecode(body) as List<dynamic>)
        .map((i) => DataMap<R>(i as Map<String, dynamic>))
        .toList();
  }
}

/// Zero-copy extension type for [http.StreamedResponse] to represent a void response.
extension type VoidResponse<R>(http.StreamedResponse _response)
    implements http.BaseResponse {}
