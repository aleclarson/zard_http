## Unreleased

- Added `timeout` property to client requests and an optional `defaultTimeout` to `HttpContractClient`.
- Introduced an injectable `retryStrategy` parameter to `HttpContractClient` for handling transport exceptions.
- Enforced command body presence on the server for contracts that declare a body schema.
- Added path-level issue metadata to standard validation error payload (`_validationErrorResponse`).

## 0.2.0

- **Breaking:** Added `close()` to `ContractClient` for explicit transport lifecycle management.
- Enforced non-null request bodies for contracts that declare a body schema (`ArgumentError` on client pre-flight).
- Added test coverage for required command body behavior.
- Updated API reference with client lifecycle and body requirement semantics.

## 0.1.0
