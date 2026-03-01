# Vision

Zard HTTP exists to make Dart HTTP work feel as direct as using plain JSON, while retaining strict correctness at system boundaries.

The intended developer experience is:
- define a contract once,
- share it between client and server,
- validate all untrusted input at the edge,
- keep core application code model-less and low-boilerplate.

## Core Intent

1. **Model-less first**: transport payloads remain `Map<String, dynamic>` / `List<dynamic>`; no generated models are required.
2. **Contracts as shared truth**: path/method/query/body/header schemas are centralized in singleton contract values.
3. **Edge validation, not domain ceremony**: Zard schemas gate ingress/egress at HTTP boundaries so inner code can move fast.
4. **Performance by default**: response wrappers avoid extra allocation via extension types over `http.StreamedResponse`.
5. **Composable, framework-agnostic core**: client/contracts/data are core; adapters (currently Shelf) bind to server frameworks.
6. **AI-friendly ergonomics**: phantom record types document payload intent for humans and AI without runtime model overhead.

## Product Shape

- `zard_http.dart`: core contracts, client, and model-less data access.
- `shelf.dart`: first-party server adapter that validates requests before handlers execute.

See:
- [Contract Semantics](./contracts.md)
- [Client Semantics](./client.md)
- [Server Adapter Semantics](./server.md)
- [Data Access Semantics](./data.md)

## Non-Goals

- ORM-like domain modeling or mandatory DTO generation.
- Hidden serialization magic beyond JSON encode/decode + schema parsing.
- Framework lock-in.
- Automatic response-body validation (current scope validates request inputs; response interpretation is caller-driven).

## Architectural Invariants

- Request contracts are reusable values, not duplicated string literals across layers.
- Query/header/body validation is schema-driven and deterministic.
- Raw/binary flows stay available (no forced JSON path).
- High-level APIs should remain smaller than equivalent hand-written `http` + parsing boilerplate.
