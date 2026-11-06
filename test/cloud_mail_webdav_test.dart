import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloudmail_player/cloud/cloud_mail_webdav.dart';
import 'package:flutter_test/flutter_test.dart';

const _credentials = CloudCredentials(
  username: 'fake@example.invalid',
  appPassword: 'fake-app-password',
);

void main() {
  late HttpServer server;
  late CloudMailWebDavClient client;
  late Uri baseUri;
  late Future<void> Function(HttpRequest request) handleRequest;

  Future<void> createClient({
    Duration timeout = const Duration(milliseconds: 500),
    int maxRetries = 0,
  }) async {
    client = CloudMailWebDavClient.forTesting(
      baseUri: baseUri,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUri = Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: '/AllMusic/',
    );
    handleRequest = (request) => _reply(request, 207, body: _rootMultistatus);
    server.listen((request) => unawaited(handleRequest(request)));
    await createClient();
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  test('Depth 0 sends Basic Auth and accepts a namespaced 207 root', () async {
    var seenDepth = '';
    var seenMethod = '';
    var seenPath = '';
    var seenAuthorization = '';
    handleRequest = (request) async {
      seenDepth = request.headers.value('depth') ?? '';
      seenMethod = request.method;
      seenPath = request.uri.path;
      seenAuthorization = request.headers.value('authorization') ?? '';
      await _reply(request, 207, body: _rootMultistatus);
    };

    await client.verifyConnection(_credentials);

    expect(seenDepth, '0');
    expect(seenMethod, 'PROPFIND');
    expect(seenPath, '/AllMusic/');
    expect(
      seenAuthorization,
      'Basic ${base64.encode(utf8.encode('fake@example.invalid:fake-app-password'))}',
    );
  });

  test('Depth 1 parses percent-encoded Cyrillic hrefs and DAV metadata', () async {
    handleRequest = (request) async {
      expect(request.headers.value('depth'), '1');
      expect(request.uri.pathSegments.where((segment) => segment.isNotEmpty), [
        'AllMusic',
        'Музыка',
      ]);
      await _reply(
        request,
        207,
        body: _multistatus(
          _response(
            '/AllMusic/%D0%9C%D1%83%D0%B7%D1%8B%D0%BA%D0%B0/',
            '<z:resourcetype><z:collection/></z:resourcetype>',
          ),
          _response(
            '/AllMusic/%D0%9C%D1%83%D0%B7%D1%8B%D0%BA%D0%B0/%E2%84%96%201.mp3',
            '<z:resourcetype/><z:getcontentlength>4</z:getcontentlength>'
                '<z:getetag>&quot;sample&quot;</z:getetag>'
                '<z:getlastmodified>Wed, 21 Oct 2015 07:28:00 GMT</z:getlastmodified>',
          ),
        ),
      );
    };

    final entries = await client.propfind(
      _credentials,
      path: 'Музыка',
      depth: 1,
    );

    expect(entries, hasLength(2));
    expect(entries.first.relativePath, 'Музыка');
    expect(entries.first.isCollection, isTrue);
    expect(entries.last.relativePath, 'Музыка/№ 1.mp3');
    expect(entries.last.isCollection, isFalse);
    expect(entries.last.sizeBytes, 4);
    expect(entries.last.etag, '"sample"');
    expect(entries.last.lastModified, DateTime.utc(2015, 10, 21, 7, 28));
  });

  for (final status in [401, 403, 404]) {
    test(
      'PROPFIND maps HTTP $status without exposing response details',
      () async {
        handleRequest = (request) async =>
            _reply(request, status, body: 'private fixture');
        final expected = status == 404
            ? CloudMailErrorCode.missingResource
            : CloudMailErrorCode.invalidCredentials;
        await expectLater(
          client.propfind(_credentials, depth: 0),
          throwsA(
            isA<CloudMailException>().having(
              (error) => error.code,
              'code',
              expected,
            ),
          ),
        );
      },
    );
  }

  test('malformed multistatus XML is rejected', () async {
    handleRequest = (request) async => _reply(request, 207, body: '<broken');
    await expectLater(
      client.propfind(_credentials, depth: 0),
      throwsA(
        isA<CloudMailException>().having(
          (error) => error.code,
          'code',
          CloudMailErrorCode.invalidResponse,
        ),
      ),
    );
  });

  test('untrusted href traversal and external origins are rejected', () async {
    handleRequest = (request) async => _reply(
      request,
      207,
      body: _multistatus(
        _response('/AllMusic/%2e%2e/private.mp3', '<z:resourcetype/>'),
      ),
    );
    await expectLater(
      client.propfind(_credentials, depth: 1),
      throwsA(
        isA<CloudMailException>().having(
          (error) => error.code,
          'code',
          CloudMailErrorCode.invalidPath,
        ),
      ),
    );

    handleRequest = (request) async => _reply(
      request,
      207,
      body: _multistatus(
        _response(
          'https://example.invalid/AllMusic/private.mp3',
          '<z:resourcetype/>',
        ),
      ),
    );
    await expectLater(
      client.propfind(_credentials, depth: 1),
      throwsA(
        isA<CloudMailException>().having(
          (error) => error.code,
          'code',
          CloudMailErrorCode.invalidPath,
        ),
      ),
    );
  });

  test('multiply encoded traversal hrefs are rejected', () async {
    for (final segment in ['%252e%252e', '%2525252e%2525252e']) {
      handleRequest = (request) async => _reply(
        request,
        207,
        body: _multistatus(
          _response('/AllMusic/$segment/private.mp3', '<z:resourcetype/>'),
        ),
      );
      await expectLater(
        client.propfind(_credentials, depth: 1),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.invalidPath,
          ),
        ),
      );
    }
  });

  test(
    'Range GET validates Cloud Mail.ru Content-Range and byte count',
    () async {
      var seenRange = '';
      var seenMethod = '';
      handleRequest = (request) async {
        seenRange = request.headers.value('range') ?? '';
        seenMethod = request.method;
        await _reply(
          request,
          206,
          bodyBytes: <int>[3, 4, 5, 6],
          headers: {'content-range': 'bytes=2-5/10'},
        );
      };

      final bytes = await client.getRange(
        _credentials,
        path: 'Музыка/№ 1.mp3',
        offset: 2,
        length: 4,
      );

      expect(seenMethod, 'GET');
      expect(seenRange, 'bytes=2-5');
      expect(bytes, <int>[3, 4, 5, 6]);
    },
  );

  test('Range GET also accepts the standard Content-Range spelling', () async {
    handleRequest = (request) async => _reply(
      request,
      206,
      bodyBytes: <int>[0, 1, 2],
      headers: {'content-range': 'bytes 0-2/9'},
    );
    final bytes = await client.getRange(
      _credentials,
      path: 'sample.mp3',
      offset: 0,
      length: 3,
    );
    expect(bytes, <int>[0, 1, 2]);
  });

  test(
    'Range GET rejects ignored ranges, bad framing, and oversized requests',
    () async {
      handleRequest = (request) async =>
          _reply(request, 200, bodyBytes: <int>[1, 2, 3, 4]);
      await expectLater(
        client.getRange(_credentials, path: 'sample.mp3', offset: 0, length: 4),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.invalidRange,
          ),
        ),
      );

      handleRequest = (request) async => _reply(
        request,
        206,
        bodyBytes: <int>[1, 2, 3, 4],
        headers: {'content-range': 'bytes=0-3/3'},
      );
      await expectLater(
        client.getRange(_credentials, path: 'sample.mp3', offset: 0, length: 4),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.invalidRange,
          ),
        ),
      );

      handleRequest = (request) async => _reply(
        request,
        206,
        bodyBytes: <int>[1, 2, 3, 4, 5],
        headers: {'content-range': 'bytes=0-3/10'},
      );
      await expectLater(
        client.getRange(_credentials, path: 'sample.mp3', offset: 0, length: 4),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.invalidRange,
          ),
        ),
      );

      var requests = 0;
      handleRequest = (request) async {
        requests++;
        await _reply(request, 206, bodyBytes: const <int>[], headers: const {});
      };
      await expectLater(
        client.getRange(
          _credentials,
          path: 'sample.mp3',
          offset: 0,
          length: CloudMailWebDavClient.maximumRangeBytes + 1,
        ),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.invalidRange,
          ),
        ),
      );
      expect(requests, 0);

      await expectLater(
        client.getRange(
          _credentials,
          path: '../outside.mp3',
          offset: 0,
          length: 1,
        ),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.invalidPath,
          ),
        ),
      );
      expect(requests, 0);
    },
  );

  test(
    'redirects are not followed and credentials stay on the original request',
    () async {
      var requests = 0;
      handleRequest = (request) async {
        requests++;
        await _reply(
          request,
          302,
          headers: {'location': 'https://example.invalid/steal'},
        );
      };
      await expectLater(
        client.propfind(_credentials, depth: 0),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.serviceUnavailable,
          ),
        ),
      );
      expect(requests, 1);
    },
  );

  test(
    'timeouts and explicit cancellation stop a delayed local request',
    () async {
      client.close();
      await createClient(timeout: const Duration(milliseconds: 100));
      handleRequest = (request) async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await _reply(request, 207, body: _rootMultistatus);
      };
      await expectLater(
        client.propfind(_credentials, depth: 0),
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.timeout,
          ),
        ),
      );

      client.close();
      await createClient(timeout: const Duration(seconds: 2));
      final requestReceived = Completer<void>();
      handleRequest = (request) async {
        if (!requestReceived.isCompleted) requestReceived.complete();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await _reply(
          request,
          206,
          bodyBytes: <int>[1],
          headers: {'content-range': 'bytes=0-0/4'},
        );
      };
      final cancellation = WebDavRequestCancellation();
      final result = client.getRange(
        _credentials,
        path: 'sample.mp3',
        offset: 0,
        length: 1,
        cancellation: cancellation,
      );
      await requestReceived.future.timeout(const Duration(seconds: 1));
      cancellation.cancel();
      await expectLater(
        result,
        throwsA(
          isA<CloudMailException>().having(
            (error) => error.code,
            'code',
            CloudMailErrorCode.cancelled,
          ),
        ),
      );
    },
  );
}

const String _rootMultistatus =
    '<x:multistatus xmlns:x="DAV:">'
    '<x:response><x:href>/AllMusic/</x:href><x:propstat><x:prop>'
    '<x:resourcetype><x:collection/></x:resourcetype>'
    '</x:prop><x:status>HTTP/1.1 200 OK</x:status></x:propstat></x:response>'
    '</x:multistatus>';

String _multistatus(String first, [String? second]) =>
    '<z:multistatus xmlns:z="DAV:">$first${second ?? ''}</z:multistatus>';

String _response(String href, String properties) =>
    '<z:response><z:href>$href</z:href><z:propstat><z:prop>$properties</z:prop>'
    '<z:status>HTTP/1.1 200 OK</z:status></z:propstat></z:response>';

Future<void> _reply(
  HttpRequest request,
  int status, {
  String body = '',
  List<int>? bodyBytes,
  Map<String, String> headers = const {},
}) async {
  try {
    request.response.statusCode = status;
    for (final entry in headers.entries) {
      request.response.headers.set(entry.key, entry.value);
    }
    request.response.add(bodyBytes ?? utf8.encode(body));
    await request.response.close();
  } on SocketException {
    // A timeout or cancellation can close the client side before this fixture replies.
  } on HttpException {
    // The fake server is local and deliberately ignores disconnected test clients.
  } catch (_) {
    // A request can be canceled while this delayed local fixture is responding.
  }
}
