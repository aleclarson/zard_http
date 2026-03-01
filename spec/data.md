# Data Access Semantics

## `DataMap<R>`

`DataMap` is the model-less accessor over `Map<String, dynamic>` used in:
- parsed server request inputs,
- parsed client JSON responses.

### Core API

- `get<T>(key)`: strict presence + runtime type check.
- `getOptional<T>(key)`: nullable extraction with runtime type check when present.
- `parse<T, RAW>(key, parser)`: typed custom mapping hook.

### Helper Parsing Extensions

- `parseBySchema(key, schema)` / optional variant
- `parseEnumByName(key, values)` / optional variant
- `parseDateTime(key)` / optional variant
  - supports ISO-8601 strings and epoch-millisecond integers.

## Response Wrappers

Extension types over `http.StreamedResponse`:
- `ObjectResponse<R>.json()` -> `Future<DataMap<R>>`
- `ListResponse<R>.json()` -> `Future<List<DataMap<R>>>`

These wrappers preserve low overhead while providing ergonomic JSON extraction.

## Byte Utilities

`Stream<List<int>>.toBytes()` collects a stream into `Uint8List` using `BytesBuilder(copy: false)`.

## Practical Intent

- Avoid transport-model boilerplate.
- Keep extraction explicit and local.
- Provide lightweight typed affordances for common parsing needs without full DTO systems.
