# API Reference

## Contracts

Contracts define the interaction boundary between client and server. They are singletons that hold path, method, and validation metadata.

### `HttpContract<R, Res>`
The base class for all contracts.
- `R`: A phantom record type for documentation.
- `Res`: The expected response type (extends `http.BaseResponse`).

#### Contract Builders
- `HttpQuery<R>(path, query, headers)`: Defines a GET request.
- `HttpCommand<R>(path, body, query, headers)`: Defines a POST (or other) request with a JSON body.
- `HttpUpload<R>(path, query, headers)`: Defines a POST request for raw bytes.

#### Builder Methods
- `.returnsMap()`: Returns `MapResponse<R>`.
- `.returnsList()`: Returns `ListResponse<R>`.
- `.returnsVoid()`: Returns `VoidResponse<R>`.
- (Default): Returns `http.StreamedResponse`.

---

## Client

### `ContractClient`
- `request(contract, {query, body, headers})`
- `close()`

### `HttpContractClient`
- Performs pre-flight validation for provided query/body/headers.
- Throws `ArgumentError` when a contract requires a body but `body` is `null`.

---

## Data Access

### `DataMap<R>`
The core class for model-less data extraction from JSON maps.

#### Methods
- `get<T>(String key)`: Returns value of type `T`. Throws if missing or type mismatch.
- `getOptional<T>(String key)`: Returns `T?`. Returns `null` if missing.
- `parse<T, RAW>(String key, T Function(RAW) parser)`: Manually maps a raw value.

#### Typed Errors
- `MissingKeyError`
- `TypeMismatchError`
- `InvalidDateTimeError`
(all extend `DataAccessError`)

#### Extensions
- `parseDateTime(String key)`: Parses ISO 8601 string or epoch milliseconds `int`.
- `parseEnumByName<T extends Enum>(String key, List<T> values)`: Maps string to enum.
- `parseBySchema<T, RAW>(String key, Schema<T> schema)`: Uses a Zard schema for nested validation.

---

## Response Wrappers

These are **zero-copy extension types** on `http.StreamedResponse`.

### `MapResponse<R>`
- `Future<DataMap<R>> json()`: Consumes the stream and returns an `DataMap` instance.

### `ListResponse<R>`
- `Future<List<DataMap<R>>> json()`: Consumes the stream and returns a list of `DataMap` instances.

### `VoidResponse<R>`
- Represents an empty or ignored response body.

---

## Shelf Adapter

Import `package:zard_http/shelf.dart`.

### `ContractRouter` (Extension on `Router`)
- `addQuery(contract, handler)`: Registers a query handler. Provides `QueryRequest`.
- `addCommand(contract, handler)`: Registers a JSON command handler. Provides `CommandRequest`.
- `addUpload(contract, handler)`: Registers a byte upload handler. Provides `UploadRequest`.

Runtime guardrails:
- `addQuery` expects an `HttpQuery` contract.
- `addCommand` expects an `HttpCommand` contract.
- `addUpload` expects an `HttpUpload` contract.
- Wrong contract family throws `ArgumentError` at registration.

Validation failures are translated to `400` JSON responses:
```json
{
  "code": "validation_error",
  "errors": ["..."]
}
```

### Request Contexts

#### `QueryRequest<R>`
- `DataMap<R>? query`: Validated query parameters.
- `Map<String, String> headers`: Request headers.

#### `CommandRequest<R>`
- `DataMap<R> body`: Validated, non-nullable JSON body.

#### `UploadRequest<R>`
- `Stream<List<int>> read()`: Returns the raw request body stream.
