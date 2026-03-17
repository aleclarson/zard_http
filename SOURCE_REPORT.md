# zard_http Source Report

Date: 2026-03-17
Scope: `lib/` source only

## Current State

`zard_http` is a small package with a compact source surface area: 673 lines across four main implementation files.

The code is easy to navigate and the responsibilities are cleanly separated:

- `lib/src/contract.dart` defines the contract model and the fluent response-type helpers.
- `lib/src/client.dart` builds and sends requests, validates input, and wraps responses.
- `lib/src/data.dart` provides the model-less data access API and response wrappers.
- `lib/src/shelf_adapter.dart` adapts contracts to `shelf` routes and request objects.

The current implementation is strongest in its happy-path ergonomics:

- The public API is small and readable.
- Client lifecycle ownership is handled cleanly.
- Request and response access patterns are consistent.
- The Shelf adapter is straightforward and keeps routing glue minimal.

## Critical Issues

No confirmed critical issues were found in the current source.

## Confirmed Concerns

### High: client-side schema parsing does not affect what is actually sent

Files:

- `lib/src/client.dart:53-78`
- `lib/src/client.dart:80-90`

The client validates `query`, `body`, and `headers`, but it does not use the parsed results. It serializes the original inputs instead.

That matters because `zard` schemas do more than reject invalid input. They can normalize values, apply defaults, and drop fields that are not part of the schema. Today those schema outputs are ignored on the wire.

Impact:

- Request normalization is not trustworthy.
- Unexpected fields can still be sent even after schema validation succeeds.
- The package’s core “strict validation at the edges” story is weakened on the client side.

### High: malformed JSON request bodies are treated as server errors

Files:

- `lib/src/shelf_adapter.dart:22-32`
- `lib/src/shelf_adapter.dart:178-182`

`ShelfCommandRequest.fromShelfRequest` calls `jsonDecode` directly. If the incoming body is malformed JSON, the thrown `FormatException` is caught by the generic `catch` in `addCommand`, which returns HTTP 500 instead of HTTP 400.

Impact:

- Client input errors are misclassified as server failures.
- Invalid JSON bypasses the package’s validation error shape.
- Operational metrics will overcount server errors.

### Medium: internal exception text is exposed in 500 responses

Files:

- `lib/src/shelf_adapter.dart:30-31`
- `lib/src/shelf_adapter.dart:56-57`
- `lib/src/shelf_adapter.dart:82-83`

Unhandled exceptions are returned to callers via `e.toString()`.

Impact:

- Internal implementation details leak over HTTP.
- Parsing and runtime error messages become part of the public API unintentionally.
- This makes production error handling harder to control and audit.

### Medium: query contracts are typed too broadly for the transport actually implemented

Files:

- `lib/src/client.dart:70-73`
- `lib/src/shelf_adapter.dart:130-131`
- `lib/src/shelf_adapter.dart:173-175`
- `lib/src/shelf_adapter.dart:223-225`

The client accepts `Map<String, dynamic>` query input, but it serializes everything through `Uri.replace(queryParameters: ...)`, which only supports flat string values. The server side reads queries through `Request.url.queryParameters`, which also collapses the transport to a single flat map.

Impact:

- Repeated keys and richer query shapes are not representable.
- The type signature suggests more flexibility than the transport supports.
- Future contract expansion around filters or arrays will be awkward.

### Medium: list/object accessors can throw raw cast errors instead of package errors

Files:

- `lib/src/data.dart:95-97`
- `lib/src/data.dart:111-113`
- `lib/src/data.dart:214-218`

`DataMap.getList`, `DataMap.getListOptional`, and `ListResponse.json()` cast list entries directly to `Map<String, dynamic>`. If a payload contains a non-map element, the caller gets a raw `_TypeError` instead of a `DataAccessError`.

Impact:

- The package’s otherwise consistent error model breaks on malformed list payloads.
- Consumers have to catch VM/runtime type errors instead of package-level exceptions.

### Low: epoch timestamps are interpreted as local time

Files:

- `lib/src/data.dart:145`
- `lib/src/data.dart:158`

`parseDateTime` and `parseDateTimeOptional` convert integer timestamps with `DateTime.fromMillisecondsSinceEpoch(value)`, which defaults to local time. String parsing may produce UTC values when the source includes a `Z` or offset.

Impact:

- Two valid representations of the same timestamp can yield different timezone semantics.
- Cross-environment behavior will vary with server locale.

## Suggestions

1. Change the client to build outgoing requests from parsed schema results, not original inputs.
2. Treat malformed JSON as a 400-level validation failure and keep the error payload shape consistent.
3. Replace raw `e.toString()` 500 bodies with a generic server error response and optional pluggable logging/error mapping.
4. Narrow query types to the flat string model that exists today, or explicitly add first-class support for repeated keys and richer query encoding.
5. Make `DataMap` and response list parsing throw library-specific errors for malformed element types.
6. Decide whether integer timestamps are UTC or local and enforce that consistently.
7. Add focused tests for malformed JSON, schema normalization on outbound requests, list element type failures, and query encoding edge cases.

## Overall Assessment

The repository is in an early but coherent state. The core design is small, readable, and directionally strong, especially around contract definitions and model-less access patterns.

The main issue is not code sprawl or obvious instability. It is that a few edge behaviors currently violate the package’s own abstraction boundary:

- validation does not fully control outbound serialization,
- malformed client input becomes a server fault,
- and some malformed payloads escape the package error model.

Those are fixable without a large redesign, but they should be addressed before the package’s API surface grows further.
