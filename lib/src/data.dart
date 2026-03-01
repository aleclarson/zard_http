import 'dart:collection';
import 'package:zard/zard.dart';

/// Model-less data accessor.
/// Shared by the server's incoming request bodies/queries, and the client's outgoing responses.
abstract interface class ObjectData<R> {
  /// Strictly extracts a value of type [T]. Throws if missing or wrong type.
  T get<T>(String key);

  /// Extracts an optional value of type [T]. Returns null if missing.
  T? getOptional<T>(String key);

  /// Parses complex data using a custom [parser] function.
  T parse<T, RAW>(String key, T Function(RAW) parser);
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

class MapObjectData<R> implements ObjectData<R> {
  final Map<String, dynamic> _data;

  MapObjectData(this._data);

  @override
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

  @override
  T? getOptional<T>(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is! T) {
      throw Exception('Value for key "$key" is not of type $T (actual type: ${value.runtimeType})');
    }
    return value;
  }

  @override
  T parse<T, RAW>(String key, T Function(RAW) parser) {
    final value = get<RAW>(key);
    return parser(value);
  }

  @override
  String toString() => _data.toString();
}

abstract class BaseResponse<R> {
  int get status;
  Map<String, String> get headers;
}

abstract class ObjectResponse<R> extends BaseResponse<R> implements ObjectData<R> {}

abstract class ListResponse<R> extends BaseResponse<R> with IterableMixin<ObjectData<R>> {}

class MapObjectResponse<R> extends ObjectResponse<R> {
  @override
  final int status;
  @override
  final Map<String, String> headers;
  final ObjectData<R> _data;

  MapObjectResponse(this.status, this.headers, Map<String, dynamic> data)
      : _data = MapObjectData<R>(data);

  @override
  T get<T>(String key) => _data.get<T>(key);

  @override
  T? getOptional<T>(String key) => _data.getOptional<T>(key);

  @override
  T parse<T, RAW>(String key, T Function(RAW) parser) =>
      _data.parse<T, RAW>(key, parser);

  @override
  String toString() => 'ObjectResponse($status, $_data)';
}

class MapListResponse<R> extends ListResponse<R> {
  @override
  final int status;
  @override
  final Map<String, String> headers;
  final List<ObjectData<R>> _items;

  MapListResponse(this.status, this.headers, List<dynamic> items)
      : _items = items.map((i) => MapObjectData<R>(i as Map<String, dynamic>)).toList();

  @override
  Iterator<ObjectData<R>> get iterator => _items.iterator;

  @override
  String toString() => 'ListResponse($status, $_items)';
}
