@TestOn('vm')
import 'dart:async';
import 'dart:isolate';
import 'package:grpc/grpc.dart' as grpc;
import 'package:test/test.dart';

import 'setup.dart';

class ClientData {
  final int port;
  final SendPort sendPort;
  ClientData({this.port, this.sendPort});
}

void client(clientData) async {
  final channel = grpc.ClientChannel(
    'localhost',
    port: clientData.port,
    options: const grpc.ChannelOptions(
      credentials: grpc.ChannelCredentials.insecure(),
    ),
  );
  TestClient(channel).infiniteStream(1).listen((count) async {
    await channel.terminate();
  }, onError: (e) {
    clientData.sendPort.send(e);
  });
}

void client2(clientData) async {
  final channel = grpc.ClientChannel(
    'localhost',
    port: clientData.port,
    options: const grpc.ChannelOptions(
      credentials: grpc.ChannelCredentials.insecure(),
    ),
  );
  Completer a = Completer();
  Completer b = Completer();
  final client = TestClient(channel);
  client.infiniteStream(1).listen((count) {
    if (!a.isCompleted) {
      a.complete();
    }
  });
  client.infiniteStream(1).listen((count) {
    if (!b.isCompleted) {
      b.complete();
    }
  });
  await Future.wait([a.future, b.future]);
  (clientData as ClientData).sendPort.send('Got two responses');
}

main() async {
  test("the client interrupting the connection does not crash the server",
      () async {
    grpc.Server server;
    server = grpc.Server([
      TestService(
          finallyCallback: expectAsync0(() {
        server.shutdown();
      }, reason: 'the producer should get cancelled'))
    ]);
    await server.serve(port: 0);
    final receivePort = ReceivePort();
    Isolate.spawn(
        client, ClientData(port: server.port, sendPort: receivePort.sendPort));
    receivePort.listen(expectAsync1((e) {
      expect(e, isA<grpc.GrpcError>());
    }, reason: 'the client should send an error from the destroyed channel'));
  });

  test(
      "Two existing clients interrupting the connection does not crash the server",
      () async {
    grpc.Server server;
    server = grpc.Server([
      TestService(
          finallyCallback: expectAsync0(() {
        print("Finally");
      }, reason: 'the producer should get cancelled'))
    ]);
    await server.serve(port: 0);
    final receivePort = ReceivePort();
    final Isolate i = await Isolate.spawn(
        client2, ClientData(port: server.port, sendPort: receivePort.sendPort));
    receivePort.listen(expectAsync1((e) {
      i.kill();
    }, reason: 'the client should send an error from the destroyed channel'));
  });
}
