// Copyright (c) 2018, the gRPC project authors. Please see the AUTHORS file
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

import '../../shared/message.dart';

typedef void SocketClosedHandler();
typedef void ActiveStateHandler(bool isActive);
typedef void ErrorHandler(error);

/// Represents one grpc communication stream.
abstract class GrpcTransportStream {
  /// Starts sending the request.
  void send();
  Stream<GrpcMessage> get incomingMessages;
  StreamSink<List<int>> get outgoingMessages;

  Future<void> terminate();
}

abstract class Transport {
  String get authority;

  /// Opens a new connection (if needed).
  ///
  /// Completes with a `Future` that completes if that connection closes.
  ///
  /// If there is no underlying connection, completes with a Future that never
  /// completes.
  Future<Future<void>> connect();

  /// Sends a request on the currently open connection.
  ///
  /// If based on an underlying connection, that has to be open.
  GrpcTransportStream makeRequest(String path, Duration timeout,
      Map<String, String> metadata, ErrorHandler onRequestFailure);

  /// Finish the underlying connection.
  ///
  /// No new streams will be accepted or can be created.
  Future<void> finish();

  /// Terminate the underlying connection.
  Future<void> terminate();

  /// Throw away the current underlying connection.
  void reset();
}
