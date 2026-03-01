# Pure Model-less HTTP Contracts for Dart

## 1. Executive Summary

This library provides a lightning-fast, boilerplate-free HTTP networking boundary for Dart. Designed from the ground up to synergize with AI coding agents and rapid integration testing, it abandons code generation and strict data classes.

Instead, endpoints are defined as CQRS-style singleton contracts (`HttpQuery` / `HttpCommand`). Data is validated at the network edges using **Zard** and accessed via a robust, model-less interface (`get`, `getOptional`, `parse`). The client enjoys a streamlined request API and functional response wrappers, while the server adapter allows developers to return idiomatic framework responses (e.g., standard Shelf `Response` objects).

## 2. Core Philosophy & AI Synergy

- **Pure Model-less Data:** JSON is kept as `Map<String, dynamic>` under the hood. No `fromJson`/`toJson` generation.
- **Edge Validation:** Zard strictly validates queries, bodies, and headers instantly on the client (pre-flight) and server (ingestion). If an AI agent writes bad data, a descriptive Zard error crashes the test immediately.
- **CQRS Contracts:** API boundaries are cleanly separated into `Queries` (GET) and `Commands` (POST/PUT/PATCH/DELETE).
- **Framework Idioms:** The server adapter wraps the _incoming_ request to provide validated `ObjectData` accessors, but gets out of your way for the _outgoing_ response, allowing standard Shelf/Dart Frog objects.

---

## 3. Architecture & API Design

### A. The Contract Definition (Shared Package)

Contracts are simple singletons. They take the routing path and the Zard schemas directly. Phantom record types (`R`) are used strictly as documentation and compile-time hints for AI agents and IDEs.

To allow the client to infer whether the response is a single object or a list, we use specific subclasses: `ObjectQuery`, `ListQuery`, `ObjectCommand`, `ListCommand`.

```dart
import 'package:zard/zard.dart';

// 1. An Object Command (e.g., POST returning a single object)
// R = ({String id, String name, String email})
final createUser = ObjectCommand<({String id, String name, String email})>(
  path: '/users',
  // Zard schemas passed directly
  body: z.object({
    'name': z.string(),
    'email': z.string().email(),
  }),
  headers: z.object({
    'x-api-key': z.string().optional(),
  }),
);

// 2. A List Query (e.g., GET returning an array)
// R = ({String id, String name})
final searchUsers = ListQuery<({String id, String name})>(
  path: '/users',
  query: z.object({
    'search': z.string(),
    'sort': z.string().optional(),
  }),
);
```

### B. Client-Side: Streamlined Execution & Access

The client API is exceptionally clean. `client.request` accepts the contract and the optional data maps. Because `createUser` is an `ObjectCommand`, Dart automatically infers that `client.request` will return an `ObjectResponse`.

```dart
void main() async {
  // 1. Execute the request.
  // Zard validates the `body` locally before the network call.
  final response = await client.request(
    createUser,
    headers: {'x-api-key': 'secret_123'},
    body: {
      'name': 'Jane Doe',
      'email': 'jane@example.com',
    },
  );

  // 2. Standard HTTP semantics
  if (response.status == 201) {

    // 3. Model-less Extraction (Runtime accessed, compile-time hinted via R)
    final id = response.get<String>('id');
    final name = response.get<String>('name');

    // 4. Advanced parsing: Support for both functions AND Zard schemas
    final createdAt = response.parse<DateTime>('created_at', parser: DateTime.parse);
    final tags = response.parse<List<String>>('tags', schema: z.array(z.string()));
  }
}
```

### C. Server-Side: Shelf Adapter & Idiomatic Responses

The router maps the contract to a handler. The adapter intercepts the request, runs the Zard validation, and passes a wrapped request to the handler. To respond, the developer uses standard Shelf `Response` objects, maintaining total control over the HTTP framework.

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void main() {
  final router = Router();

  // The adapter handles routing and Zard validation automatically.
  // Invalid requests return a 400 Bad Request before the handler runs.
  router.addCommand(createUser, (request) async {

    // 1. Data is guaranteed safe by Zard. Accessed via the same model-less API.
    final name = request.body!.get<String>('name');
    final email = request.body!.get<String>('email');

    final dbUser = await db.insertUser(name, email);

    // 2. Idiomatic Framework Response. No contract.response() required!
    // We trust the developer/AI to return the correct JSON shape matching <R>.
    return Response(
      201,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': dbUser.id,
        'name': dbUser.name,
        'email': dbUser.email,
      }),
    );
  });
}
```

---

## 4. Core Interface Definitions

### 1. Model-less Data Accessor

Shared by the server's incoming request bodies/queries, and the client's outgoing responses.

```dart
abstract interface class ObjectData<R> {
  /// Strictly extracts a value of type [T]. Throws if missing or wrong type.
  T get<T>(String key);

  /// Extracts an optional value of type [T]. Returns null if missing.
  T? getOptional<T>(String key);

  /// Parses complex data using either a custom [parser] function OR a [ZardType].
  T parse<T, RAW>(
    String key, {
    T Function(RAW)? parser,
    ZardType<T>? schema,
  });
}
```

### 2. Client Response Wrappers

```dart
abstract class BaseResponse<R> {
  int get status;
  Map<String, String> get headers;
}

abstract class ObjectResponse<R> extends BaseResponse<R> implements ObjectData<R> {}
abstract class ListResponse<R> extends BaseResponse<R> implements Iterable<ObjectData<R>> {}
```

### 3. Contracts

```dart
abstract class HttpContract<R, Res extends BaseResponse<R>> {
  String get method;
  String get path;
  ZardObject? get query;
  ZardObject? get body;
  ZardObject? get headers;
}

// CQRS Subclasses map the Contract to the expected Client Response type
class ObjectQuery<R> extends HttpContract<R, ObjectResponse<R>> { ... }
class ListQuery<R> extends HttpContract<R, ListResponse<R>> { ... }
class ObjectCommand<R> extends HttpContract<R, ObjectResponse<R>> { ... }
class ListCommand<R> extends HttpContract<R, ListResponse<R>> { ... }
```

### 4. The Client

```dart
abstract class ContractClient {
  /// Executes the request. The generic [Res] seamlessly ensures that passing
  /// an `ObjectCommand` returns an `ObjectResponse`, etc.
  Future<Res> request<R, Res extends BaseResponse<R>>(
    HttpContract<R, Res> contract, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });
}
```

## 5. Summary of the Request Lifecycle

1. **Definition:** `createUser` singleton is defined with `path` and Zard schemas.
2. **Client Call:** `client.request(createUser, body: {...})`.
3. **Pre-flight Validation:** Client runs the `body` map through the Zard schema. Throws beautifully formatted `ClientValidationException` on failure.
4. **Network:** JSON sent via HTTP POST.
5. **Server Ingestion:** Shelf middleware parses JSON and runs it through the same Zard schema. Returns `400 Bad Request` with Zard errors on failure.
6. **Server Handling:** Handler reads safe data via `request.body!.get<String>('name')`.
7. **Server Response:** Handler returns a standard `shelf.Response.ok(...)`.
8. **Client Resolution:** Client receives JSON, skips runtime validation (for speed), wraps it in `ObjectResponse<R>`, and returns it to the caller.
