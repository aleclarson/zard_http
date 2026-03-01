# Pure Model-less HTTP Contracts for Dart

## 1. Executive Summary

This library provides a lightning-fast, boilerplate-free HTTP networking boundary for Dart. Designed from the ground up to synergize with AI coding agents and rapid integration testing, it abandons code generation and strict data classes.

Instead, endpoints are defined as CQRS-style singleton contracts (`HttpQuery` / `HttpCommand`). Data is validated at the network edges using **Zard** and accessed via a robust, model-less interface (`get`, `parseDateTime`, `parseBySchema`). The client enjoys a streamlined request API and zero-copy response wrappers, while the server adapter allows developers to return idiomatic framework responses.

## 2. Core Philosophy & AI Synergy

- **Pure Model-less Data:** JSON is kept as `Map<String, dynamic>` under the hood. No `fromJson`/`toJson` generation.
- **Edge Validation:** Zard strictly validates queries, bodies, and headers instantly on the client (pre-flight) and server (ingestion).
- **CQRS Contracts:** API boundaries are cleanly separated into `Queries` (GET) and `Commands` (POST/PUT/PATCH/DELETE).
- **Zero-Copy Performance:** Response wrappers (`ObjectResponse`, `ListResponse`) are implemented as **extension types** on `http.StreamedResponse`.
- **Framework Adapters:** The library is modular. Use `zard_http/zard_http.dart` for the core and `zard_http/shelf.dart` for Shelf-specific routing.

---

## 3. Architecture & API Design

### A. The Contract Definition (Shared Package)

Contracts are simple singletons. They take the routing path and the Zard schemas directly. Phantom record types (`R`) are used strictly as documentation and compile-time hints.

Commands **require** a `body` schema.

```dart
import 'package:zard/zard.dart';
import 'package:zard_http/zard_http.dart';

// 1. An Object Command (e.g., POST returning a single object)
// R = ({String id, String name, String email})
final createUser = ObjectCommand<({String id, String name, String email})>(
  path: '/users',
  // Required body schema
  body: z.map({
    'name': z.string(),
    'email': z.string().email(),
  }),
  headers: z.map({
    'x-api-key': z.string().optional(),
  }),
);

// 2. A List Query (e.g., GET returning an array)
// R = ({String id, String name})
final searchUsers = ListQuery<({String id, String name})>(
  path: '/users',
  query: z.map({
    'search': z.string(),
    'sort': z.string().optional(),
  }),
);
```

### B. Client-Side: Streamlined Execution & Access

The client API returns extension types wrapping the raw `http.StreamedResponse`. Accessing JSON data is asynchronous to allow for stream consumption.

```dart
void main() async {
  final client = HttpContractClient('https://api.example.com');

  // 1. Execute the request.
  final response = await client.request(
    createUser,
    body: {
      'name': 'Jane Doe',
      'email': 'jane@example.com',
    },
  );

  // 2. Standard HTTP semantics
  if (response.statusCode == 201) {

    // 3. Model-less Extraction (Awaited .json() returns ObjectData)
    final data = await response.json();
    
    final id = data.get<String>('id');
    final name = data.get<String>('name');

    // 4. Advanced parsing: Built-in extensions
    final createdAt = data.parseDateTime('created_at'); // Supports ISO 8601 & Epoch ms
    final tags = data.parseBySchema('tags', z.list(z.string()));
  }
}
```

### C. Server-Side: Shelf Adapter & Request Context

The router maps the contract to a handler. The adapter provides a specialized `QueryRequest` (no body) or `CommandRequest` (guaranteed body).

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zard_http/shelf.dart';

void main() {
  final router = Router();

  // addCommand provides a CommandRequest with a non-nullable body
  router.addCommand(createUser, (request) async {

    // 1. Data is guaranteed safe by Zard. 
    final name = request.body.get<String>('name');
    final email = request.body.get<String>('email');

    // 2. Idiomatic Framework Response.
    return Response.ok(jsonEncode({
      'id': '123',
      'name': name,
      'email': email,
    }));
  });
}
```

---

## 4. Core Interface Definitions

### 1. Model-less Data Accessor (`ObjectData`)

```dart
class ObjectData<R> {
  T get<T>(String key);
  T? getOptional<T>(String key);
  T parse<T, RAW>(String key, T Function(RAW) parser);
}

// Extensions provide:
// - parseBySchema(key, schema)
// - parseEnumByName(key, values)
// - parseDateTime(key)
```

### 2. Client Response Wrappers (Extension Types)

```dart
// Zero-copy wrappers for http.StreamedResponse
extension type ObjectResponse<R>(http.StreamedResponse _res) implements http.BaseResponse {
  Future<ObjectData<R>> json();
}

extension type ListResponse<R>(http.StreamedResponse _res) implements http.BaseResponse {
  Future<List<ObjectData<R>>> json();
}
```

### 3. Server Request Contexts

```dart
abstract class QueryRequest<R> {
  ObjectData<R>? get query;
  Map<String, String> get headers;
}

abstract class CommandRequest<R> extends QueryRequest<R> {
  ObjectData<R> get body; // Non-nullable
}
```

### 4. Contracts

```dart
abstract class HttpContract<R, Res extends http.BaseResponse> {
  String get method;
  String get path;
  Schema<Map<String, dynamic>>? get query;
  Schema<Map<String, dynamic>>? get body;
  Schema<Map<String, dynamic>>? get headers;
}
```

## 5. Summary of the Request Lifecycle

1. **Definition:** `createUser` singleton is defined with `path` and Zard schemas.
2. **Client Call:** `client.request(createUser, body: {...})`.
3. **Pre-flight Validation:** Client runs the `body` map through the Zard schema. Throws `ZardError` on failure.
4. **Network:** JSON sent via HTTP POST.
5. **Server Ingestion:** Shelf middleware parses JSON and runs it through the same Zard schema. Returns `400 Bad Request` with Zard issues on failure.
6. **Server Handling:** Handler reads safe data via `request.body.get<String>('name')`.
7. **Server Response:** Handler returns a standard `shelf.Response`.
8. **Client Resolution:** Client receives `http.StreamedResponse`, wraps it in `ObjectResponse<R>`, and returns it.
9. **Data Access:** Caller calls `await response.json()` to consume the stream and extract data.
