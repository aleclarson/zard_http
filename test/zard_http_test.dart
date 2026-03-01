import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';
import 'package:zard/zard.dart';
import 'package:zard_http/shelf.dart';
import 'package:http/http.dart' as http;

// Contracts
final createUser = ObjectCommand<({String id, String name, String email})>(
  path: '/users',
  body: z.object({
    'name': z.string(),
    'email': z.string().email(),
  }),
);

final searchUsers = ListQuery<({String id, String name})>(
  path: '/users',
  query: z.object({
    'search': z.string(),
  }),
);

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
        final name = request.body!.get<String>('name');
        final email = request.body!.get<String>('email');

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

      server = await shelf_io.serve(router, 'localhost', 0);
      baseUrl = 'http://${server.address.host}:${server.port}';
      client = HttpContractClient(baseUrl);
    });

    tearDown(() async {
      await server.close();
    });

    test('ObjectCommand works', () async {
      final response = await client.request(
        createUser,
        body: {'name': 'Jane Doe', 'email': 'jane@example.com'},
      );

      expect(response.status, 201);
      expect(response.get<String>('id'), '123');
      expect(response.get<String>('name'), 'Jane Doe');
      expect(response.get<String>('email'), 'jane@example.com');

      // Test parse extensions
      final createdAt = response.parseDateTime('created_at');
      expect(createdAt.year, 2023);

      final updatedAt = response.parseDateTime('updated_at');
      expect(updatedAt.year, 2023);
      expect(updatedAt.millisecondsSinceEpoch, 1672574400000);

      final tags = response.parseBySchema<List<dynamic>, List<dynamic>>('tags', z.array(z.string()));
      expect(tags, contains('dart'));

      final role = response.parseEnumByName('role', UserRole.values);
      expect(role, UserRole.admin);

      // Test optional variants
      expect(response.parseDateTimeOptional('created_at'), isNotNull);
      expect(response.parseDateTimeOptional('missing'), isNull);
      expect(response.parseBySchemaOptional('tags', z.array(z.string())), isNotNull);
      expect(response.parseBySchemaOptional('missing', z.array(z.string())), isNull);
      expect(response.parseEnumByNameOptional('role', UserRole.values), UserRole.admin);
      expect(response.parseEnumByNameOptional('missing', UserRole.values), isNull);
    });

    test('ListQuery works', () async {
      final response = await client.request(
        searchUsers,
        query: {'search': 'test'},
      );

      expect(response.status, 200);
      final list = response.toList();
      expect(list.length, 2);
      expect(list[0].get<String>('name'), contains('test'));
    });

    test('Validation fails on client', () async {
      expect(
        () => client.request(createUser, body: {'name': 'Jane Doe', 'email': 'not-an-email'}),
        throwsA(isA<ZardError>()),
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
      expect(body['errors'], isNotNull);
    });
  });
}
