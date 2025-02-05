// filepath: /Users/sudonym/Documents/GitHub/hostr/nostr_service/lib/server.dart
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class RelayServer {
  final _router = Router();

  RelayServer() {
    _router.get('/list-pending', _listPendingActions);
    _router.post('/take-action', _takeAction);
  }

  Response _listPendingActions(Request request) {
    // Implement logic to list pending actions
    return Response.ok('Listing pending actions...');
  }

  Future<Response> _takeAction(Request request) async {
    // Implement logic to take action
    final payload = await request.readAsString();
    return Response.ok('Taking action with payload: $payload');
  }

  void start() async {
    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(_router);
    final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
    print('Server listening on port ${server.port}');
  }
}
