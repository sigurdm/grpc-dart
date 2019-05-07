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
import 'dart:html';

import '../shared/status.dart';
import 'call.dart';
import 'channel.dart';
import 'connection.dart';
import 'method.dart';
import 'options.dart';
import 'transport/transport.dart';
import 'transport/xhr_transport.dart';

/// A client channel to a grpc-web endpoint.
abstract class GrpcWebClientChannel implements ClientChannel {
  factory GrpcWebClientChannel.xhr(Uri uri,
          {ChannelOptions options: const ChannelOptions()}) =>
      new XhrGrpcWebClientChannelImpl(uri, options);
}

class XhrGrpcWebClientChannelImpl
    implements GrpcWebClientChannel, RequestHandler {
  final Uri uri;
  ChannelOptions options;
  bool _isShutdown = false;
  List<ClientCall> pendingCalls = <ClientCall>[];

  XhrGrpcWebClientChannelImpl(this.uri, this.options);

  String get authority => uri.authority;

  @override
  GrpcTransportStream makeRequest(String path, Duration timeout,
      Map<String, String> metadata, errorHandler) {
    final _request = HttpRequest();
    _request.open('POST', uri.resolve(path).toString());

    return XhrTransportStream(_request, metadata, (e) {
      throw "Connection error $e";
    })
      ..send();
  }

  @override
  ClientCall<Q, R> createCall<Q, R>(
      ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options) {
    if (_isShutdown) throw GrpcError.unavailable('Channel shutting down.');
    final call = ClientCall(method, requests, options)..sendRequest(this);
    pendingCalls.add(call);
    return call;
  }

  @override
  Future<void> shutdown() async {
    _isShutdown = true;
  }

  @override
  Future<void> terminate() async {
    pendingCalls.forEach((call) => call.cancel());
    _isShutdown = true;
  }
}
