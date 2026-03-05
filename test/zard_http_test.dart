import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';
import 'package:zard/zard.dart';
import 'package:zard_http/shelf.dart';
import 'package:http/http.dart' as http;

// Contracts
final createUser = HttpCommand<({String id, String name, String email})>(
  path: '/users',
  body: z.map({
    'name': z.string(),
    'email': z.string().email(),
  }),
).returnsMap();

final searchUsers = HttpQuery<({String id, String name})>(
  path: '/users',
  query: z.map({
    'search': z.string(),
  }),
).returnsList();

final rawText = HttpQuery<String>(path: '/raw');

final uploadBytes = HttpUpload<String>(path: '/upload');

final voidTest = HttpCommand<String>(
  path: '/void',
  body: z.map({}),
).returnsVoid();

final timeoutTest = HttpQuery<String>(path: '/timeout_test');
final retryTest = HttpQuery<String>(path: '/retry_test');

enum UserRole { admin, member }

void main() {
  group('zard_http', () {
    late Router router;
    late HttpServer server;
    late String baseUrl;
    late ContractClient client;

    setUp(() async {
      router = Router();

      router.addCommand(createUser, (request) async {
        final name = request.body.get<String>('name');
        final email = request.body.get<String>('email');

        return Response(201,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': '123',
              'name': name,
              'email': email,
              'created_at': '2023-01-01T12:00:00Z',
              'updated_at': 1672574400000,
              'tags': ['dart', 'zard'],
              'role': 'admin',
            }));
      });

      router.addQuery(searchUsers, (request) async {
        final search = request.query!.get<String>('search');
        return Response.ok(
            jsonEncode([
              {'id': '1', 'name': 'User 1 with $search'},
              {'id': '2', 'name': 'User 2 with $search'},
            ]),
            headers: {'Content-Type': 'application/json'});
      });

      router.addQuery(rawText, (request) async {
        return Response.ok('Plain text response');
      });

      router.addUpload(uploadBytes, (request) async {
        final bytes = await request.read().toBytes();
        return Response.ok('Received ${bytes.length} bytes');
      });

      router.addCommand(voidTest, (request) async {
        return Response(204);
      });

      router.get('/timeout_test', (Request request) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Response.ok('delayed');
      });

      int failCount = 0;
      router.get('/retry_test', (Request request) async {
        if (failCount < 2) {
          failCount++;
          return Response.internalServerError();
        }
        return Response.ok('success');
      });

      server = await shelf_io.serve(router, 'localhost', 0);
      baseUrl = 'http://${server.address.host}:${server.port}';
      client = HttpContractClient(baseUrl);
    });

    tearDown(() async {
      client.close();
      await server.close();
    });

    test('Router rejects wrong contract family', () {
      expect(
        () => router.addCommand(rawText, (request) async => Response.ok('bad')),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () =>
            router.addQuery(createUser, (request) async => Response.ok('bad')),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () =>
            router.addUpload(createUser, (request) async => Response.ok('bad')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ObjectCommand works', () async {
      final response = await client.request(
        createUser,
        body: {'name': 'Jane Doe', 'email': 'jane@example.com'},
      );

      expect(response.statusCode, 201);
      final data = await response.json();
      expect(data.get<String>('id'), '123');
      expect(data.get<String>('name'), 'Jane Doe');
      expect(data.get<String>('email'), 'jane@example.com');

      // Test parse extensions
      final createdAt = data.parseDateTime('created_at');
      expect(createdAt.year, 2023);

      final updatedAt = data.parseDateTime('updated_at');
      expect(updatedAt.year, 2023);
      expect(updatedAt.millisecondsSinceEpoch, 1672574400000);

      final tags = data.parseBySchema<List<dynamic>, List<dynamic>>(
          'tags', z.list(z.string()));
      expect(tags, contains('dart'));

      final role = data.parseEnumByName('role', UserRole.values);
      expect(role, UserRole.admin);

      // Test optional variants
      expect(data.parseDateTimeOptional('created_at'), isNotNull);
      expect(data.parseDateTimeOptional('missing'), isNull);
      expect(data.parseBySchemaOptional('tags', z.list(z.string())), isNotNull);
      expect(data.parseBySchemaOptional('missing', z.list(z.string())), isNull);
      expect(data.parseEnumByNameOptional('role', UserRole.values),
          UserRole.admin);
      expect(data.parseEnumByNameOptional('missing', UserRole.values), isNull);
    });

    test('DataMap getList and getOptionalList work', () {
      final data = DataMap<String>({
        'tags': ['dart', 'zard'],
        'numbers': [1, 2, 3],
      });

      expect(data.getList<String>('tags'), equals(['dart', 'zard']));
      expect(data.getList<int>('numbers'), equals([1, 2, 3]));
      expect(data.getOptionalList<String>('tags'), equals(['dart', 'zard']));
      expect(data.getOptionalList<String>('missing'), isNull);

      expect(
        () => data.getList<String>('numbers'),
        throwsA(isA<TypeError>()),
      );
    });

    test('DataMap throws typed access errors', () {
      final data = DataMap<String>({'count': 1, 'when': true});

      expect(
        () => data.get<String>('missing'),
        throwsA(isA<MissingKeyError>()),
      );

      expect(
        () => data.get<String>('count'),
        throwsA(isA<TypeMismatchError>()),
      );

      expect(
        () => data.parseDateTime('when'),
        throwsA(isA<InvalidDateTimeError>()),
      );
    });

    test('ListQuery works', () async {
      final response = await client.request(
        searchUsers,
        query: {'search': 'test'},
      );

      expect(response.statusCode, 200);
      final list = await response.json();
      expect(list.length, 2);
      expect(list[0].get<String>('name'), contains('test'));
    });

    test('RawQuery works', () async {
      final response = await client.request(rawText);

      expect(response.statusCode, 200);
      expect(await response.stream.bytesToString(), 'Plain text response');
    });

    test('Upload bytes works', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final response = await client.request(uploadBytes, body: bytes);

      expect(response.statusCode, 200);
      expect(await response.stream.bytesToString(), 'Received 5 bytes');
    });

    test('VoidCommand works', () async {
      final response = await client.request(voidTest, body: {});
      expect(response.statusCode, 204);
    });

    test('Validation fails on client', () async {
      expect(
        () => client.request(createUser,
            body: {'name': 'Jane Doe', 'email': 'not-an-email'}),
        throwsA(isA<ZardError>()),
      );
    });

    test('Command body is required on client', () async {
      expect(
        client.request(createUser),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Validation fails on server', () async {
      // Manual post to bypass client-side validation
      final res = await http.post(
        Uri.parse('$baseUrl/users'),
        body: jsonEncode({'name': 'Jane Doe', 'email': 'not-an-email'}),
        headers: {'Content-Type': 'application/json'},
      );

      expect(res.statusCode, 400);
      final body = jsonDecode(res.body);
      expect(body['code'], 'validation_error');
      final errors = body['errors'] as List;
      expect(errors.isNotEmpty, isTrue);
      expect(errors.first['message'], isNotNull);
      expect(errors.first['path'], isNotNull);
    });

    test('Timeout works', () async {
      expect(
        () => client.request(timeoutTest,
            timeout: const Duration(milliseconds: 10)),
        throwsA(isA<
            Exception>()), // Usually TimeoutException or similar from http client
      );
    });

    test('Retry strategy works', () async {
      int attempts = 0;

      // We need a way to make it throw an Exception.
      // Response.internalServerError() doesn't throw, it just returns a 500 response.
      // So wait, my test needs to throw an error for retry to happen (e.g. SocketException).
      // Let's close the client connection or use a bad port for a true exception.

      final badClient = HttpContractClient(
        'http://localhost:1',
        retryStrategy: (attempt, error) async {
          attempts = attempt;
          return attempt < 3;
        },
      );

      try {
        await badClient.request(retryTest);
      } catch (_) {}

      expect(attempts, 3);
      badClient.close();
    });
  });
}
