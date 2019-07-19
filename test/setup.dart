// Copyright (c) 2019, the gRPC project authors. Please see the AUTHORS file
// for details. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import 'dart:async';
import 'package:grpc/grpc.dart' as grpc;

class TestClient extends grpc.Client {
  static final _$infiniteStream = grpc.ClientMethod<int, int>(
      '/test.TestService/infiniteStream',
          (int value) => [value],
          (List<int> value) => value[0]);

  TestClient(grpc.ClientChannel channel) : super(channel);
  grpc.ResponseStream<int> infiniteStream(int request,
      {grpc.CallOptions options}) {
    final call = $createCall(_$infiniteStream, Stream.fromIterable([request]),
        options: options);
    return grpc.ResponseStream(call);
  }
}

class TestService extends grpc.Service {
  String get $name => 'test.TestService';
  final void Function() finallyCallback;

  TestService({this.finallyCallback}) {
    $addMethod(grpc.ServiceMethod<int, int>('infiniteStream', infiniteStream,
        false, true, (List<int> value) => value[0], (int value) => [value]));
  }

  Stream<int> infiniteStream(grpc.ServiceCall call, Future request) async* {
    int count = await request;
    try {
      while (true) {
        count++;
        yield count % 128;
        // TODO(sigurdm): Ideally we should not need this to get the
        //  cancel-event.
        //  See: https://github.com/dart-lang/sdk/issues/34775
        await Future.delayed(Duration(milliseconds: 1));
      }
    } finally {
      finallyCallback();
    }
  }
}
