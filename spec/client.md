# Client Semantics

Primary API: `HttpContractClient.request(contract, {query, body, headers})`.

## Execution Pipeline

1. **Pre-flight validation**
   - If contract schema and corresponding argument are both present, parse with Zard.
2. **URL composition**
   - Normalize `baseUrl` + contract `path` slash boundaries.
   - Serialize query values via `toString()` into URI query params.
3. **Request shaping**
   - Build `http.Request(method, uri)`.
   - Auto-set `Content-Type: application/json` for map bodies.
   - Encode map body as JSON.
   - Pass byte bodies (`Uint8List`/`List<int>`) as raw bytes.
   - Fallback non-map/non-bytes body to `toString()`.
4. **Transport**
   - Send via internal `http.Client.send`.
5. **Response wrapping**
   - Raw contracts return `http.StreamedResponse`.
   - Object contracts return `ObjectResponse<R>`.
   - List contracts return `ListResponse<R>`.

## Behavioral Guarantees

- Return type follows contract family without manual casting at call sites.
- No model code generation required for consumption.
- Validation happens before outbound request when relevant input is provided.

## Operational Notes

- Response streams are single-consumption; `.json()` consumes stream.
- Client lifecycle currently has no explicit `close()` API in `ContractClient`; ownership of transport client is internal to `HttpContractClient`.
