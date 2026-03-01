import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zard/zard.dart';

/// Model-less data accessor.
/// Shared by the server's incoming request bodies/queries, and the client's outgoing responses.
class ObjectData<R> {
  final Map<String, dynamic> _data;

  ObjectData(this._data);

  /// Strictly extracts a value of type [T]. Throws if missing or wrong type.
  T get<T>(String key) {
    final value = _data[key];
    if (value == null && !_data.containsKey(key)) {
      throw Exception('Key "$key" not found in data');
    }
    if (value is! T) {
      throw Exception('Value for key "$key" is not of type $T (actual type: ${value.runtimeType})');
    }
    return value;
  }

  /// Extracts an optional value of type [T]. Returns null if missing.
  T? getOptional<T>(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is! T) {
      throw Exception('Value for key "$key" is not of type $T (actual type: ${value.runtimeType})');
    }
    return value;
  }

  /// Parses complex data using a custom [parser] function.
  T parse<T, RAW>(String key, T Function(RAW) parser) {
    final value = get<RAW>(key);
    return parser(value);
  }

  @override
  String toString() => _data.toString();
}

extension ObjectDataExtension<R> on ObjectData<R> {
  /// Parses complex data using a [Schema].
  T parseBySchema<T, RAW>(String key, Schema<T> schema) => parse<T, RAW>(key, schema.parse);

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

/// Zero-copy extension type for [http.Response] to add model-less extraction.
extension type ObjectResponse<R>(http.Response _response) implements http.BaseResponse {
  Map<String, dynamic> get _json => jsonDecode(_response.body);

  T get<T>(String key) => ObjectData<R>(_json).get<T>(key);

  T? getOptional<T>(String key) => ObjectData<R>(_json).getOptional<T>(key);

  T parse<T, RAW>(String key, T Function(RAW) parser) =>
      ObjectData<R>(_json).parse<T, RAW>(key, parser);
}

extension ObjectResponseExtension<R> on ObjectResponse<R> {
  /// Parses complex data using a [Schema].
  T parseBySchema<T, RAW>(String key, Schema<T> schema) => parse<T, RAW>(key, schema.parse);

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

/// Zero-copy extension type for [http.Response] to add model-less extraction for lists.
extension type ListResponse<R>(http.Response _response) implements http.BaseResponse {
  List<dynamic> get _json => jsonDecode(_response.body);

  List<ObjectData<R>> toList() =>
      _json.map((i) => ObjectData<R>(i as Map<String, dynamic>)).toList();
}
