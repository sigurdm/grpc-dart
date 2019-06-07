///
//  Generated code. Do not modify.
//  source: test.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

import 'dart:async' as $async;

import 'package:grpc/service_api.dart' as $grpc;
import 'empty.pb.dart' as $0;
import 'messages.pb.dart' as $1;
export 'test.pb.dart';

class TestServiceClient extends $grpc.Client {
  static final _$emptyCall = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/grpc.testing.TestService/EmptyCall',
      ($0.Empty value) => value.writeToBuffer(),
      (List<int> value) => $0.Empty.fromBuffer(value));
  static final _$unaryCall =
      $grpc.ClientMethod<$1.SimpleRequest, $1.SimpleResponse>(
          '/grpc.testing.TestService/UnaryCall',
          ($1.SimpleRequest value) => value.writeToBuffer(),
          (List<int> value) => $1.SimpleResponse.fromBuffer(value));
  static final _$cacheableUnaryCall =
      $grpc.ClientMethod<$1.SimpleRequest, $1.SimpleResponse>(
          '/grpc.testing.TestService/CacheableUnaryCall',
          ($1.SimpleRequest value) => value.writeToBuffer(),
          (List<int> value) => $1.SimpleResponse.fromBuffer(value));
  static final _$streamingOutputCall = $grpc.ClientMethod<
          $1.StreamingOutputCallRequest, $1.StreamingOutputCallResponse>(
      '/grpc.testing.TestService/StreamingOutputCall',
      ($1.StreamingOutputCallRequest value) => value.writeToBuffer(),
      (List<int> value) => $1.StreamingOutputCallResponse.fromBuffer(value));
  static final _$streamingInputCall = $grpc.ClientMethod<
          $1.StreamingInputCallRequest, $1.StreamingInputCallResponse>(
      '/grpc.testing.TestService/StreamingInputCall',
      ($1.StreamingInputCallRequest value) => value.writeToBuffer(),
      (List<int> value) => $1.StreamingInputCallResponse.fromBuffer(value));
  static final _$fullDuplexCall = $grpc.ClientMethod<
          $1.StreamingOutputCallRequest, $1.StreamingOutputCallResponse>(
      '/grpc.testing.TestService/FullDuplexCall',
      ($1.StreamingOutputCallRequest value) => value.writeToBuffer(),
      (List<int> value) => $1.StreamingOutputCallResponse.fromBuffer(value));
  static final _$halfDuplexCall = $grpc.ClientMethod<
          $1.StreamingOutputCallRequest, $1.StreamingOutputCallResponse>(
      '/grpc.testing.TestService/HalfDuplexCall',
      ($1.StreamingOutputCallRequest value) => value.writeToBuffer(),
      (List<int> value) => $1.StreamingOutputCallResponse.fromBuffer(value));
  static final _$unimplementedCall = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/grpc.testing.TestService/UnimplementedCall',
      ($0.Empty value) => value.writeToBuffer(),
      (List<int> value) => $0.Empty.fromBuffer(value));

  TestServiceClient($grpc.ClientChannel channel, {$grpc.CallOptions options})
      : super(channel, options: options);

  $grpc.ResponseFuture<$0.Empty> emptyCall($0.Empty request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$emptyCall, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }

  $grpc.ResponseFuture<$1.SimpleResponse> unaryCall($1.SimpleRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$unaryCall, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }

  $grpc.ResponseFuture<$1.SimpleResponse> cacheableUnaryCall(
      $1.SimpleRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(
        _$cacheableUnaryCall, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }

  $grpc.ResponseStream<$1.StreamingOutputCallResponse> streamingOutputCall(
      $1.StreamingOutputCallRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(
        _$streamingOutputCall, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseStream(call);
  }

  $grpc.ResponseFuture<$1.StreamingInputCallResponse> streamingInputCall(
      $async.Stream<$1.StreamingInputCallRequest> request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$streamingInputCall, request, options: options);
    return $grpc.ResponseFuture(call);
  }

  $grpc.ResponseStream<$1.StreamingOutputCallResponse> fullDuplexCall(
      $async.Stream<$1.StreamingOutputCallRequest> request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$fullDuplexCall, request, options: options);
    return $grpc.ResponseStream(call);
  }

  $grpc.ResponseStream<$1.StreamingOutputCallResponse> halfDuplexCall(
      $async.Stream<$1.StreamingOutputCallRequest> request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$halfDuplexCall, request, options: options);
    return $grpc.ResponseStream(call);
  }

  $grpc.ResponseFuture<$0.Empty> unimplementedCall($0.Empty request,
      {$grpc.CallOptions options}) {
    final call = $createCall(
        _$unimplementedCall, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }
}

abstract class TestServiceBase extends $grpc.Service {
  String get $name => 'grpc.testing.TestService';

  TestServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'EmptyCall',
        emptyCall_Pre,
        false,
        false,
        (List<int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SimpleRequest, $1.SimpleResponse>(
        'UnaryCall',
        unaryCall_Pre,
        false,
        false,
        (List<int> value) => $1.SimpleRequest.fromBuffer(value),
        ($1.SimpleResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.SimpleRequest, $1.SimpleResponse>(
        'CacheableUnaryCall',
        cacheableUnaryCall_Pre,
        false,
        false,
        (List<int> value) => $1.SimpleRequest.fromBuffer(value),
        ($1.SimpleResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StreamingOutputCallRequest,
            $1.StreamingOutputCallResponse>(
        'StreamingOutputCall',
        streamingOutputCall_Pre,
        false,
        true,
        (List<int> value) => $1.StreamingOutputCallRequest.fromBuffer(value),
        ($1.StreamingOutputCallResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StreamingInputCallRequest,
            $1.StreamingInputCallResponse>(
        'StreamingInputCall',
        streamingInputCall,
        true,
        false,
        (List<int> value) => $1.StreamingInputCallRequest.fromBuffer(value),
        ($1.StreamingInputCallResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StreamingOutputCallRequest,
            $1.StreamingOutputCallResponse>(
        'FullDuplexCall',
        fullDuplexCall,
        true,
        true,
        (List<int> value) => $1.StreamingOutputCallRequest.fromBuffer(value),
        ($1.StreamingOutputCallResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StreamingOutputCallRequest,
            $1.StreamingOutputCallResponse>(
        'HalfDuplexCall',
        halfDuplexCall,
        true,
        true,
        (List<int> value) => $1.StreamingOutputCallRequest.fromBuffer(value),
        ($1.StreamingOutputCallResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'UnimplementedCall',
        unimplementedCall_Pre,
        false,
        false,
        (List<int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
  }

  $async.Future<$0.Empty> emptyCall_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return emptyCall(call, await request);
  }

  $async.Future<$1.SimpleResponse> unaryCall_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return unaryCall(call, await request);
  }

  $async.Future<$1.SimpleResponse> cacheableUnaryCall_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return cacheableUnaryCall(call, await request);
  }

  $async.Stream<$1.StreamingOutputCallResponse> streamingOutputCall_Pre(
      $grpc.ServiceCall call, $async.Future request) async* {
    yield* streamingOutputCall(
        call, (await request) as $1.StreamingOutputCallRequest);
  }

  $async.Future<$0.Empty> unimplementedCall_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return unimplementedCall(call, await request);
  }

  $async.Future<$0.Empty> emptyCall($grpc.ServiceCall call, $0.Empty request);
  $async.Future<$1.SimpleResponse> unaryCall(
      $grpc.ServiceCall call, $1.SimpleRequest request);
  $async.Future<$1.SimpleResponse> cacheableUnaryCall(
      $grpc.ServiceCall call, $1.SimpleRequest request);
  $async.Stream<$1.StreamingOutputCallResponse> streamingOutputCall(
      $grpc.ServiceCall call, $1.StreamingOutputCallRequest request);
  $async.Future<$1.StreamingInputCallResponse> streamingInputCall(
      $grpc.ServiceCall call,
      $async.Stream<$1.StreamingInputCallRequest> request);
  $async.Stream<$1.StreamingOutputCallResponse> fullDuplexCall(
      $grpc.ServiceCall call,
      $async.Stream<$1.StreamingOutputCallRequest> request);
  $async.Stream<$1.StreamingOutputCallResponse> halfDuplexCall(
      $grpc.ServiceCall call,
      $async.Stream<$1.StreamingOutputCallRequest> request);
  $async.Future<$0.Empty> unimplementedCall(
      $grpc.ServiceCall call, $0.Empty request);
}

class UnimplementedServiceClient extends $grpc.Client {
  static final _$unimplementedCall = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/grpc.testing.UnimplementedService/UnimplementedCall',
      ($0.Empty value) => value.writeToBuffer(),
      (List<int> value) => $0.Empty.fromBuffer(value));

  UnimplementedServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options})
      : super(channel, options: options);

  $grpc.ResponseFuture<$0.Empty> unimplementedCall($0.Empty request,
      {$grpc.CallOptions options}) {
    final call = $createCall(
        _$unimplementedCall, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }
}

abstract class UnimplementedServiceBase extends $grpc.Service {
  String get $name => 'grpc.testing.UnimplementedService';

  UnimplementedServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'UnimplementedCall',
        unimplementedCall_Pre,
        false,
        false,
        (List<int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
  }

  $async.Future<$0.Empty> unimplementedCall_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return unimplementedCall(call, await request);
  }

  $async.Future<$0.Empty> unimplementedCall(
      $grpc.ServiceCall call, $0.Empty request);
}

class ReconnectServiceClient extends $grpc.Client {
  static final _$start = $grpc.ClientMethod<$1.ReconnectParams, $0.Empty>(
      '/grpc.testing.ReconnectService/Start',
      ($1.ReconnectParams value) => value.writeToBuffer(),
      (List<int> value) => $0.Empty.fromBuffer(value));
  static final _$stop = $grpc.ClientMethod<$0.Empty, $1.ReconnectInfo>(
      '/grpc.testing.ReconnectService/Stop',
      ($0.Empty value) => value.writeToBuffer(),
      (List<int> value) => $1.ReconnectInfo.fromBuffer(value));

  ReconnectServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions options})
      : super(channel, options: options);

  $grpc.ResponseFuture<$0.Empty> start($1.ReconnectParams request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$start, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }

  $grpc.ResponseFuture<$1.ReconnectInfo> stop($0.Empty request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$stop, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }
}

abstract class ReconnectServiceBase extends $grpc.Service {
  String get $name => 'grpc.testing.ReconnectService';

  ReconnectServiceBase() {
    $addMethod($grpc.ServiceMethod<$1.ReconnectParams, $0.Empty>(
        'Start',
        start_Pre,
        false,
        false,
        (List<int> value) => $1.ReconnectParams.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.ReconnectInfo>(
        'Stop',
        stop_Pre,
        false,
        false,
        (List<int> value) => $0.Empty.fromBuffer(value),
        ($1.ReconnectInfo value) => value.writeToBuffer()));
  }

  $async.Future<$0.Empty> start_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return start(call, await request);
  }

  $async.Future<$1.ReconnectInfo> stop_Pre(
      $grpc.ServiceCall call, $async.Future request) async {
    return stop(call, await request);
  }

  $async.Future<$0.Empty> start(
      $grpc.ServiceCall call, $1.ReconnectParams request);
  $async.Future<$1.ReconnectInfo> stop(
      $grpc.ServiceCall call, $0.Empty request);
}
