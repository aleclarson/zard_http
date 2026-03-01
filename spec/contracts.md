# Contract Semantics

Contracts are the canonical definition of an HTTP boundary. They carry:
- `method`
- `path`
- optional `query` schema
- optional `headers` schema
- optional `body` schema
- expected response wrapper type

Base type: `HttpContract<R, Res extends http.BaseResponse>`.

## Type Parameters

- `R`: phantom documentation type (commonly a record type) for payload shape intent.
- `Res`: response category at call sites (`ObjectResponse`, `ListResponse`, or raw `StreamedResponse`).

## Contract Families

### Query Contracts
- `ObjectQuery<R>`
- `ListQuery<R>`
- `RawQuery<R>`

Default method: `GET`.
No request body schema.

### Command Contracts
- `ObjectCommand<R>`
- `ListCommand<R>`
- `RawCommand<R>`

Default method: `POST` (override allowed).
Require a JSON-map `body` schema.

### Upload Contracts
- `ObjectUpload<R>`
- `ListUpload<R>`
- `RawUpload<R>`

Default method: `POST` (override allowed).
No body schema; intended for raw byte streams.

## Contract Authoring Rules

1. Contracts SHOULD be declared as shared top-level singletons.
2. Paths MUST be adapter-compatible route templates.
3. Query/header schemas MUST target string-keyed maps.
4. Command body schemas MUST accept JSON-map payloads.
5. Upload contracts SHOULD be used when body is binary or non-JSON.

## Error Model

- Schema parse failures raise `ZardError` and are surfaced by caller/adapter policy.
- Unknown runtime contract type in client wrapping is treated as exceptional misuse.
