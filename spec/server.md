# Server Adapter Semantics (Shelf)

Entry point: `package:zard_http/shelf.dart`.

`Router` extension methods:
- `addQuery(contract, handler)`
- `addCommand(contract, handler)`
- `addUpload(contract, handler)`

Each method registers `contract.method + contract.path` and converts incoming `shelf.Request` into typed request contexts.

## Request Contexts

- `QueryRequest<R>`
  - `query`: validated `DataMap<R>?`
  - `headers`: raw/validated header map
- `CommandRequest<R>`
  - query + headers
  - `body`: validated `DataMap<R>`
- `UploadRequest<R>`
  - query + headers
  - `read()`: byte stream passthrough

## Validation Flow

1. Validate headers when schema exists.
2. Validate query parameters when schema exists.
3. For commands, decode JSON body and parse with body schema.
4. Handlers run only after adapter-side parsing succeeds.

## Error Translation

- `ZardError` -> `400 Bad Request`, JSON body: `{ "errors": [message, ...] }`.
- Any other exception -> `500 Internal Server Error` with string body.

## Adapter Intent

- Keep framework glue thin.
- Centralize request validation so business handlers can assume parsed inputs.
- Preserve raw upload path for high-throughput/binary workflows.
