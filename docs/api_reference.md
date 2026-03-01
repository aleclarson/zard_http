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
- `body`: `Schema<Map<String, dynamic>>?` for request body validation.
- `headers`: `Schema<Map<String, dynamic>>?` for request header validation.

---

### Contract Subclasses

#### `ObjectQuery<R>`
- **Method**: Defaults to `GET`.
- **Response**: `ObjectResponse<R>`.
- Used for fetching a single JSON object.

#### `ListQuery<R>`
- **Method**: Defaults to `GET`.
- **Response**: `ListResponse<R>`.
- Used for fetching an array of JSON objects.

#### `RawQuery<R>`
- **Method**: Defaults to `GET`.
- **Response**: `http.StreamedResponse`.
- Used for fetching non-JSON data.

#### `ObjectCommand<R>`
- **Method**: Defaults to `POST`.
- **Response**: `ObjectResponse<R>`.
- **Note**: Requires a `body` schema.

#### `ListCommand<R>`
- **Method**: Defaults to `POST`.
- **Response**: `ListResponse<R>`.
- **Note**: Requires a `body` schema.

#### `RawCommand<R>`
- **Method**: Defaults to `POST`.
- **Response**: `http.StreamedResponse`.
- **Note**: Requires a `body` schema.

---

## Data Access

### `ObjectData<R>`
The core class for model-less data extraction.

#### Methods
- `get<T>(String key)`: Returns value of type `T`. Throws if missing or type mismatch.
- `getOptional<T>(String key)`: Returns `T?`. Returns `null` if missing.
- `parse<T, RAW>(String key, T Function(RAW) parser)`: Manually maps a raw value.

#### Extensions
- `parseDateTime(String key)`: Parses ISO 8601 string or epoch milliseconds `int`.
- `parseEnumByName<T extends Enum>(String key, List<T> values)`: Maps string to enum.
- `parseBySchema<T, RAW>(String key, Schema<T> schema)`: Uses a Zard schema for nested validation.
- *All extensions include `Optional` variants.*

---

## Response Wrappers

These are **zero-copy extension types** on `http.StreamedResponse`.

### `ObjectResponse<R>`
- `Future<ObjectData<R>> json()`: Consumes the stream and returns an `ObjectData` instance.

### `ListResponse<R>`
- `Future<List<ObjectData<R>>> json()`: Consumes the stream and returns a list of `ObjectData` instances.

---

## Client

### `HttpContractClient`
Implementation of the client-side contract execution.

#### Constructor
- `HttpContractClient(String baseUrl, {http.Client? client})`

#### Methods
- `Future<Res> request<R, Res>(HttpContract<R, Res> contract, { ... })`:
    - Validates `body`, `query`, and `headers` locally before sending.
    - Automatically wraps the response based on the contract type.

---

## Shelf Adapter

Import `package:zard_http/shelf.dart`.

### `ContractRouter` (Extension on `Router`)
- `addQuery(contract, handler)`: Registers a GET-style handler.
- `addCommand(contract, handler)`: Registers a POST-style handler.

### Request Contexts

#### `QueryRequest<R>`
- `ObjectData<R>? query`: Validated query parameters.
- `Map<String, String> headers`: Request headers.

#### `CommandRequest<R>`
- Extends `QueryRequest<R>`.
- `ObjectData<R> body`: Validated, non-nullable request body.
