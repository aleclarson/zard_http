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
- `Res`: response category at call sites (`MapResponse`, `ListResponse`, `VoidResponse`, or raw `StreamedResponse`).

## Contract Families

Contracts are defined using base builders that can be specialized for response types.

### 1. `HttpQuery<R>`
- Purpose: `GET` requests.
- Body: Always `null`.
- Default Response: `http.StreamedResponse`.

### 2. `HttpCommand<R>`
- Purpose: `POST`/`PUT` requests with JSON bodies.
- Body: Required `Schema<Map<String, dynamic>>`.
- Default Response: `http.StreamedResponse`.

### 3. `HttpUpload<R>`
- Purpose: `POST` requests with raw byte bodies.
- Body: Always `null` (server handles raw bytes).
- Default Response: `http.StreamedResponse`.

## Builder Methods

Each builder can be specialized:
- `.returnsMap()`: Returns `MapQuery<R>`, `MapCommand<R>`, or `MapUpload<R>`.
- `.returnsList()`: Returns `ListQuery<R>`, `ListCommand<R>`, or `ListUpload<R>`.
- `.returnsVoid()`: Returns `VoidQuery<R>`, `VoidCommand<R>`, or `VoidUpload<R>`.

---

## Contract Authoring Rules

1. Contracts SHOULD be declared as shared top-level singletons.
2. Paths MUST be adapter-compatible route templates.
3. Query/header schemas MUST target string-keyed maps.
4. Command body schemas MUST accept JSON-map payloads.
5. Upload contracts SHOULD be used when body is binary or non-JSON.

## Error Model

- Schema parse failures raise `ZardError` and are surfaced by caller/adapter policy.
- Unknown runtime contract type in client wrapping is treated as exceptional misuse.
