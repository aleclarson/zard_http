# Zard HTTP

Lightning-fast, boilerplate-free HTTP networking for Dart. Designed for AI synergy and model-less data access.

Zard HTTP was born from a simple desire: to make network requests in Dart feel as direct and lightweight as possible, without sacrificing safety. We wanted a way to define contracts that both the client and server could trust, using strict validation at the edges while keeping the data itself flexible and model-free. It's built for developers who want to move fast, skip the code generation, and just work with their data.

## Features
- **Pure Model-less Data:** JSON is kept as `Map<String, dynamic>`. No code generation or `fromJson`/`toJson` boilerplate.
- **Edge Validation:** Every request is strictly validated at the network boundary (client-side pre-flight and server-side ingestion) using [Zard](https://pub.dev/packages/zard).
- **CQRS Contracts:** API boundaries are defined as singleton contracts, separating Queries (GET), Commands (JSON POST), and Uploads (Byte POST).
- **Zero-Copy Performance:** Response wrappers are implemented as **extension types** on `http.StreamedResponse` for maximum efficiency.
- **Framework Agnostic:** The core library works in any environment; includes a first-class Shelf adapter.

## Quick Start

### 1. Define a Contract (Shared)
```dart
import 'package:zard/zard.dart';
import 'package:zard_http/zard_http.dart';

// R = ({String id, String name})
final createUser = ObjectCommand<({String id, String name})>(
  path: '/users',
  body: z.map({
    'name': z.string(),
  }),
);
```

### 2. Client Usage
```dart
final client = HttpContractClient('https://api.example.com');

final response = await client.request(createUser, body: {'name': 'Jane Doe'});

if (response.statusCode == 201) {
  final data = await response.json(); // Awaited stream consumption
  print(data.get<String>('name'));    // Model-less access
}
```

### 3. Server Usage (Shelf)
```dart
import 'package:zard_http/shelf.dart';

final router = Router();

// request.body is non-nullable and guaranteed safe by Zard
router.addCommand(createUser, (request) async {
  final name = request.body.get<String>('name');
  
  return Response.ok(jsonEncode({
    'id': '123',
    'name': name,
  }));
});
```

### 4. Upload Usage
```dart
// 1. Define Upload Contract
final uploadImage = RawUpload<String>(path: '/upload');

// 2. Client
await client.request(uploadImage, body: myImageBytes);

// 3. Server
router.addUpload(uploadImage, (request) async {
  final bytes = await request.read().toBytes(); // Use helper or stream manually
  // Validation is handler's responsibility
  return Response.ok('Saved ${bytes.length} bytes');
});
```

## Installation

```bash
dart pub add zard_http
```

## Documentation
For a full list of classes, methods, and extensions, see the [API Reference](docs/api_reference.md).

## In-depth

### Singleton Contracts
Endpoints are defined as global constants. This allows both the client and server to share the same validation logic and routing metadata. Phantom record types (`R`) are used to document the expected JSON shape for developers and AI agents.

### Strict Request Validation
When using `client.request`, the provided `body`, `query`, or `headers` maps are validated against the contract's Zard schemas before the request is even sent. On the server, the adapter validates the incoming data before your handler is ever called, automatically returning a `400 Bad Request` with descriptive Zard issues on failure.

### Asynchronous Data Access
To maintain zero-copy performance, `ObjectResponse` and `ListResponse` wrap the raw `http.StreamedResponse`. Calling `.json()` asynchronously consumes the stream and decodes the JSON into an `DataMap` accessor.

### Model-less Extraction
`DataMap` provides a robust API for extracting data without classes:
- `get<T>(key)`: Strict extraction.
- `parseDateTime(key)`: Handles ISO 8601 strings and epoch integers.
- `parseEnumByName(key, values)`: Safe enum mapping.
- `parseBySchema(key, schema)`: Nested validation for complex structures.

## License
MIT
