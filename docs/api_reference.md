# API Reference

## Contracts

Contracts define the interaction boundary between client and server. They are singletons that hold path, method, and validation metadata.

### `HttpContract<R, Res>`
The base abstract class for all contracts.
- `R`: A phantom record type for documentation.
- `Res`: The expected response type (extends `http.BaseResponse`).

#### Properties
- `method`: HTTP method (e.g., 'GET', 'POST').
- `path`: URL path template.
- `query`: `Schema<Map<String, dynamic>>?` for query parameter validation.
- `body`: `Schema<dynamic>?` for request body validation.
- `headers`: `Schema<Map<String, dynamic>>?` for request header validation.

---

### Contract Subclasses

#### `ObjectQuery<R>`, `ListQuery<R>`, `RawQuery<R>`
- **Method**: Defaults to `GET`.
- **Body**: Always `null`.

#### `ObjectCommand<R>`, `ListCommand<R>`, `RawCommand<R>`
- **Method**: Defaults to `POST`.
- **Body**: Required `Schema<Map<String, dynamic>>`.

#### `ObjectUpload<R>`, `ListUpload<R>`, `RawUpload<R>`
- **Method**: Defaults to `POST`.
- **Body**: Always `null` schema. Validation is the server's responsibility.

---

## Data Access

### `ObjectData<R>`
The core class for model-less data extraction from JSON maps.

#### Methods
- `get<T>(String key)`: Returns value of type `T`. Throws if missing or type mismatch.
- `getOptional<T>(String key)`: Returns `T?`. Returns `null` if missing.
- `parse<T, RAW>(String key, T Function(RAW) parser)`: Manually maps a raw value.

#### Extensions
- `parseDateTime(String key)`: Parses ISO 8601 string or epoch milliseconds `int`.
- `parseEnumByName<T extends Enum>(String key, List<T> values)`: Maps string to enum.
- `parseBySchema<T, RAW>(String key, Schema<T> schema)`: Uses a Zard schema for nested validation.

---

## Response Wrappers

These are **zero-copy extension types** on `http.StreamedResponse`.

### `ObjectResponse<R>`
- `Future<ObjectData<R>> json()`: Consumes the stream and returns an `ObjectData` instance.

### `ListResponse<R>`
- `Future<List<ObjectData<R>>> json()`: Consumes the stream and returns a list of `ObjectData` instances.

---

## Shelf Adapter

Import `package:zard_http/shelf.dart`.

### `ContractRouter` (Extension on `Router`)
- `addQuery(contract, handler)`: Registers a GET handler. Provides `QueryRequest`.
- `addCommand(contract, handler)`: Registers a JSON handler. Provides `CommandRequest`.
- `addUpload(contract, handler)`: Registers a Byte handler. Provides `UploadRequest`.

### Request Contexts

#### `QueryRequest<R>`
- `ObjectData<R>? query`: Validated query parameters.
- `Map<String, String> headers`: Request headers.

#### `CommandRequest<R>`
- `ObjectData<R> body`: Validated, non-nullable JSON body.

#### `UploadRequest<R>`
- `Stream<List<int>> read()`: Returns the raw request body stream.
