# Zard HTTP

Lightning-fast, boilerplate-free HTTP networking for Dart. Designed for AI synergy and model-less data access.

## Features
- **Pure Model-less Data:** JSON is kept as `Map<String, dynamic>`. No code generation or `fromJson`/`toJson` boilerplate.
- **Edge Validation:** Every request and response is strictly validated at the network boundary using [Zard](https://pub.dev/packages/zard).
- **CQRS Contracts:** API boundaries are defined as singleton contracts, separating Queries (GET) from Commands (POST/PUT/PATCH/DELETE).
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

## Installation

Add to your `pubspec.yaml`:
```yaml
dependencies:
  zard_http: ^0.1.0
```
