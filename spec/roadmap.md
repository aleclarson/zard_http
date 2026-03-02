# Roadmap (Inferred)

This roadmap reflects likely architectural next steps implied by the current codebase and API shape.

## Progress Snapshot

- ✅ Client disposal implemented (`ContractClient.close()` + owned-client handling).
- ✅ Client-side required-body pre-flight enforced for body-schema contracts.
- ✅ Shelf validation errors now include machine-readable `code` plus message list.

## 1) Stabilize Core Semantics

1. **Contract-type strictness**
   - Narrow Shelf adapter registration APIs to contract families (`addCommand` should only accept command contracts, etc.) to prevent misuse.
2. **Body requirements parity**
   - Enforce command body presence consistently on both client and server (today validation is conditional on provided body).
3. **Error taxonomy**
   - Replace generic `Exception` throws in data access with focused typed errors for better observability and caller control. ✅ (DataAccessError + specific subclasses)

## 2) Transport Lifecycle & Reliability

1. **Client disposal**
   - Add explicit `close()` to `ContractClient` / `HttpContractClient` for owned `http.Client` lifecycle control.
2. **Timeout/retry hooks**
   - Introduce opt-in request timeout policy and injectable retry strategy without coupling to one backend.
3. **Cancellation support**
   - Evaluate cooperative cancellation pattern for long-running requests and uploads.

## 3) Validation Depth & Schema Ergonomics

1. **Response validation (opt-in)**
   - Add optional response schema support on contracts for boundary-hardening where needed.
2. **Header/query coercion policy**
   - Clarify and standardize string-to-typed coercion behavior for server query/header parsing.
3. **Upload validation affordances**
   - Provide optional helper utilities for content-type/size checks while preserving raw stream control.

## 4) Server Adapter Evolution

1. **Adapter modularity**
   - Keep core independent; add additional adapters only as thin translation layers.
2. **Consistent error payload contract**
   - Standardize machine-readable error bodies (codes + paths + messages), not only message arrays.
   - ✅ Partial: code + messages implemented (`code: validation_error`, `errors: []`).
   - 🔄 Remaining: path-level issue metadata.
3. **Middleware interoperability docs**
   - Document adapter behavior with auth/logging/compression middleware ordering.

## 5) Developer Experience

1. **Path parameter ergonomics**
   - Add first-class typed path-param extraction pattern aligned with contract definitions.
2. **Testing utilities**
   - Provide lightweight fixtures/helpers for contract-based integration tests.
3. **Examples by use-case**
   - Expand docs with focused examples: pagination query, multipart-like raw upload, auth headers, enum/date parsing.

## 6) Release Discipline (v0.x)

1. **Architectural-first breaking changes**
   - Continue direct cleanup over deprecation when semantics are wrong.
2. **Minor-version bumps for breakage**
   - On public API breaks, run `version_assist bump --minor`.
3. **Spec-first workflow**
   - Treat `spec/` as behavior authority; update specs before major implementation shifts.
