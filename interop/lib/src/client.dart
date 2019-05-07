// Copyright (c) 2017, the gRPC project authors. Please see the AUTHORS file
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
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:grpc/grpc.dart';
import 'generated/empty.pb.dart';
import 'generated/messages.pb.dart';
import 'generated/test.pbgrpc.dart';

const _headerEchoKey = 'x-grpc-test-echo-initial';
const _headerEchoData = 'test_initial_metadata_value';

const _trailerEchoKey = 'x-grpc-test-echo-trailing-bin';
const _trailerEchoData = 'q6ur'; // 0xababab in base64

class Tester {
  String serverHost;
  String serverHostOverride;
  int _serverPort;
  String testCase;
  bool _useTls;
  bool _useTestCA;
  String defaultServiceAccount;
  String oauthScope;
  String serviceAccountKeyFile;
  String _serviceAccountJson;

  String get serviceAccountJson =>
      _serviceAccountJson ??= _readServiceAccountJson();

  String _readServiceAccountJson() {
    if (serviceAccountKeyFile?.isEmpty ?? true) {
      throw 'Service account key file not specified.';
    }
    return new File(serviceAccountKeyFile).readAsStringSync();
  }

  void set serverPort(String value) {
    if (value == null) {
      _serverPort = null;
      return;
    }
    try {
      _serverPort = int.parse(value);
    } catch (e) {
      print('Invalid port "$value": $e');
    }
  }

  void set useTls(String value) {
    _useTls = value != 'false';
  }

  void set useTestCA(String value) {
    _useTestCA = value == 'true';
  }

  ClientChannel channel;
  TestServiceClient client;
  UnimplementedServiceClient unimplementedServiceClient;

  bool validate() {
    if (serverHost == null) {
      print('Must specify --server_host');
      return false;
    }
    if (_serverPort == null) {
      print('Must specify --server_port');
      return false;
    }

    return true;
  }

  Future<void> runTest() async {
    ChannelCredentials credentials;
    if (_useTls) {
      List<int> trustedRoot;
      if (_useTestCA) {
        trustedRoot = new File('ca.pem').readAsBytesSync();
      }
      credentials = new ChannelCredentials.secure(
          certificates: trustedRoot, authority: serverHostOverride);
    } else {
      credentials = const ChannelCredentials.insecure();
    }

    final options = new ChannelOptions(credentials: credentials);
    channel =
        new ClientChannel(serverHost, port: _serverPort, options: options);
    client = new TestServiceClient(channel);
    unimplementedServiceClient = new UnimplementedServiceClient(channel);
    await runTestCase();
    await channel.shutdown();
  }

  Future<void> runTestCase() async {
    switch (testCase) {
      case 'empty_unary':
        return emptyUnary();
      case 'cacheable_unary':
        return cacheableUnary();
      case 'large_unary':
        return largeUnary();
      case 'client_compressed_unary':
        return clientCompressedUnary();
      case 'server_compressed_unary':
        return serverCompressedUnary();
      case 'client_streaming':
        return clientStreaming();
      case 'client_compressed_streaming':
        return clientCompressedStreaming();
      case 'server_streaming':
        return serverStreaming();
      case 'server_compressed_streaming':
        return serverCompressedStreaming();
      case 'ping_pong':
        return pingPong();
      case 'empty_stream':
        return emptyStream();
      case 'compute_engine_creds':
        return computeEngineCreds();
      case 'service_account_creds':
        return serviceAccountCreds();
      case 'jwt_token_creds':
        return jwtTokenCreds();
      case 'oauth2_auth_token':
        return oauth2AuthToken();
      case 'per_rpc_creds':
        return perRpcCreds();
      case 'custom_metadata':
        return customMetadata();
      case 'status_code_and_message':
        return statusCodeAndMessage();
      case 'unimplemented_method':
        return unimplementedMethod();
      case 'unimplemented_service':
        return unimplementedService();
      case 'cancel_after_begin':
        return cancelAfterBegin();
      case 'cancel_after_first_response':
        return cancelAfterFirstResponse();
      case 'timeout_on_sleeping_server':
        return timeoutOnSleepingServer();
      default:
        print('Unknown test case: $testCase');
    }
  }

  /// This test verifies that implementations support zero-size messages.
  /// Ideally, client implementations would verify that the request and response
  /// were zero bytes serialized, but this is generally prohibitive to perform,
  /// so is not required.
  ///
  /// Procedure:
  /// 1. Client calls EmptyCall with the default Empty message
  ///
  /// Client asserts:
  /// * call was successful
  /// * response is non-null
  Future<void> emptyUnary() async {
    final response = await client.emptyCall(new Empty());
    if (response == null) throw 'Expected non-null response.';
    if (response is! Empty) throw 'Expected Empty response.';
  }

  /// This test verifies that gRPC requests marked as cacheable use GET verb
  /// instead of POST, and that server sets appropriate cache control headers
  /// for the response to be cached by a proxy. This test requires that the
  /// server is behind a caching proxy. Use of current timestamp in the request
  /// prevents accidental cache matches left over from previous tests.
  ///
  /// Procedure:
  /// 1. Client calls CacheableUnaryCall with `SimpleRequest` request with
  ///    payload set to current timestamp. Timestamp format is irrelevant, and
  ///    resolution is in nanoseconds.
  ///    Client adds a `x-user-ip` header with value `1.2.3.4` to the request.
  ///    This is done since some proxys such as GFE will not cache requests from
  ///    localhost.
  ///    Client marks the request as cacheable by setting the cacheable flag in
  ///    the request context. Longer term this should be driven by the method
  ///    option specified in the proto file itself.
  /// 2. Client calls CacheableUnaryCall again immediately with the same request
  ///    and configuration as the previous call.
  ///
  /// Client asserts:
  /// * Both calls were successful
  /// * The payload body of both responses is the same.
  Future<void> cacheableUnary() async {
    throw 'Not implemented';
  }

  /// This test verifies unary calls succeed in sending messages, and touches on
  /// flow control (even if compression is enabled on the channel).
  ///
  /// Procedure:
  /// 1. Client calls UnaryCall with:
  ///     {
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * response payload body is 314159 bytes in size
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response message against a golden response
  Future<void> largeUnary() async {
    final payload = new Payload()..body = new Uint8List(271828);
    final request = new SimpleRequest()
      ..responseSize = 314159
      ..payload = payload;
    final response = await client.unaryCall(request);
    final receivedBytes = response.payload.body.length;
    if (receivedBytes != 314159) {
      throw 'Response payload mismatch. Expected 314159 bytes, '
          'got ${receivedBytes}.';
    }
  }

  /// This test verifies the client can compress unary messages by sending two
  /// unary calls, for compressed and uncompressed payloads. It also sends an
  /// initial probing request to verify whether the server supports the
  /// CompressedRequest feature by checking if the probing call fails with an
  /// `INVALID_ARGUMENT` status.
  ///
  /// Procedure:
  /// 1. Client calls UnaryCall with the feature probe, an *uncompressed*
  ///    message:
  ///     {
  ///       expect_compressed: {
  ///         value: true
  ///       }
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  /// 1. Client calls UnaryCall with the *compressed* message:
  ///     {
  ///       expect_compressed: {
  ///         value: true
  ///       }
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  /// 1. Client calls UnaryCall with the *uncompressed* message:
  ///     {
  ///     expect_compressed: {
  ///         value: false
  ///       }
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  ///
  /// Client asserts:
  /// * First call failed with `INVALID_ARGUMENT` status.
  /// * Subsequent calls were successful.
  /// * Response payload body is 314159 bytes in size.
  /// * Clients are free to assert that the response payload body contents are
  ///   zeros and comparing the entire response message against a golden
  ///   response.
  Future<void> clientCompressedUnary() async {
    throw 'Not implemented';
  }

  /// This test verifies the server can compress unary messages. It sends two
  /// unary requests, expecting the server's response to be compressed or not
  /// according to the `response_compressed` boolean.
  ///
  /// Whether compression was actually performed is determined by the
  /// compression bit in the response's message flags. *Note that some languages
  /// may not have access to the message flags, in which case the client will be
  /// unable to verify that the `response_compressed` boolean is obeyed by the
  /// server*.
  ///
  /// Procedure:
  /// 1. Client calls UnaryCall with `SimpleRequest`:
  ///     {
  ///       response_compressed: {
  ///         value: true
  ///       }
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  ///     {
  ///       response_compressed: {
  ///         value: false
  ///       }
  ///       response_size: 314159
  ///       payload:  {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * if supported by the implementation, when `response_compressed` is true,
  ///   the response MUST have the compressed message flag set.
  /// * if supported by the implementation, when `response_compressed` is false,
  ///   the response MUST NOT have the compressed message flag set.
  /// * response payload body is 314159 bytes in size in both cases.
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response message against a golden response
  Future<void> serverCompressedUnary() async {
    throw 'Not implemented';
  }

  /// This test verifies that client-only streaming succeeds.
  ///
  /// Procedure:
  /// 1. Client calls StreamingInputCall
  /// 2. Client sends:
  ///     {
  ///       payload: {
  ///         body: 27182 bytes of zeros
  ///       }
  ///     }
  /// 3. Client then sends:
  ///     {
  ///       payload: {
  ///         body: 8 bytes of zeros
  ///       }
  ///     }
  /// 4. Client then sends:
  ///     {
  ///       payload: {
  ///         body: 1828 bytes of zeros
  ///       }
  ///     }
  /// 5. Client then sends:
  ///     {
  ///       payload: {
  ///         body: 45904 bytes of zeros
  ///       }
  ///     }
  /// 6. Client half-closes
  ///
  /// Client asserts:
  /// * call was successful
  /// * response aggregated_payload_size is 74922
  Future<void> clientStreaming() async {
    StreamingInputCallRequest createRequest(int bytes) {
      final request = new StreamingInputCallRequest()..payload = new Payload();
      request.payload.body = new Uint8List(bytes);
      return request;
    }

    Stream<StreamingInputCallRequest> requests() async* {
      yield createRequest(27182);
      yield createRequest(8);
      yield createRequest(1828);
      yield createRequest(45904);
    }

    final response = await client.streamingInputCall(requests());
    if (response.aggregatedPayloadSize != 74922) {
      throw 'Response mismatch. Expected 74922, '
          'got ${response.aggregatedPayloadSize}';
    }
  }

  /// This test verifies the client can compress requests on per-message basis
  /// by performing a two-request streaming call. It also sends an initial
  /// probing request to verify whether the server supports the
  /// CompressedRequest feature by checking if the probing call fails with an
  /// `INVALID_ARGUMENT` status.
  ///
  /// Procedure:
  /// 1. Client calls `StreamingInputCall` and sends the following
  ///    feature-probing *uncompressed* `StreamingInputCallRequest` message
  ///     {
  ///       expect_compressed: {
  ///         value: true
  ///       }
  ///       payload:  {
  ///         body: 27182 bytes of zeros
  ///       }
  ///     }
  ///    If the call does not fail with `INVALID_ARGUMENT`, the test fails.
  ///    Otherwise, we continue.
  /// 1. Client calls `StreamingInputCall` again, sending the *compressed*
  ///    message
  ///     {
  ///       expect_compressed: {
  ///         value: true
  ///       }
  ///       payload: {
  ///         body: 27182 bytes of zeros
  ///       }
  ///     }
  /// 1. And finally, the *uncompressed* message
  ///     {
  ///       expect_compressed: {
  ///         value: false
  ///       }
  ///       payload:  {
  ///         body: 45904 bytes of zeros
  ///       }
  ///     }
  /// 1. Client half-closes
  ///
  /// Client asserts:
  /// * First call fails with `INVALID_ARGUMENT`.
  /// * Next calls succeeds.
  /// * Response aggregated payload size is 73086.
  Future<void> clientCompressedStreaming() async {
    throw 'Not implemented';
  }

  /// This test verifies that server-only streaming succeeds.
  ///
  /// Procedure:
  /// 1. Client calls StreamingOutputCall with `StreamingOutputCallRequest`:
  ///     {
  ///       response_parameters: {
  ///         size: 31415
  ///       }
  ///       response_parameters: {
  ///         size: 9
  ///       }
  ///       response_parameters: {
  ///         size: 2653
  ///       }
  ///       response_parameters: {
  ///         size: 58979
  ///       }
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * exactly four responses
  /// * response payload bodies are sized (in order): 31415, 9, 2653, 58979
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response messages against golden responses
  Future<void> serverStreaming() async {
    final expectedResponses = [31415, 9, 2653, 58979];

    final request = new StreamingOutputCallRequest()
      ..responseParameters.addAll(expectedResponses
          .map((size) => new ResponseParameters()..size = size));

    final responses = await client.streamingOutputCall(request).toList();
    if (responses.length != 4) {
      throw 'Incorrect number of responses (${responses.length}).';
    }
    final responseLengths =
        responses.map((response) => response.payload.body.length).toList();

    if (!new ListEquality().equals(responseLengths, expectedResponses)) {
      throw 'Incorrect response lengths received (${responseLengths.join(', ')} != ${expectedResponses.join(', ')})';
    }
  }

  /// This test verifies that the server can compress streaming messages and
  /// disable compression on individual messages, expecting the server's
  /// response to be compressed or not according to the `response_compressed`
  /// boolean.
  ///
  /// Whether compression was actually performed is determined by the
  /// compression bit in the response's message flags. *Note that some languages
  /// may not have access to the message flags, in which case the client will be
  /// unable to verify that the `response_compressed` boolean is obeyed by the
  /// server*.
  ///
  /// Procedure:
  /// 1. Client calls StreamingOutputCall with `StreamingOutputCallRequest`:
  ///     {
  ///       response_parameters: {
  ///         compressed: {
  ///           value: true
  ///         }
  ///         size: 31415
  ///       }
  ///       response_parameters: {
  ///         compressed: {
  ///           value: false
  ///         }
  ///         size: 92653
  ///       }
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * exactly two responses
  /// * if supported by the implementation, when `response_compressed` is false,
  ///   the response's messages MUST NOT have the compressed message flag set.
  /// * if supported by the implementation, when `response_compressed` is true,
  ///   the response's messages MUST have the compressed message flag set.
  /// * response payload bodies are sized (in order): 31415, 92653
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response messages against golden responses
  Future<void> serverCompressedStreaming() async {
    throw 'Not implemented';
  }

  /// This test verifies that full duplex bidi is supported.
  ///
  /// Procedure:
  /// 1. Client calls FullDuplexCall with:
  ///     {
  ///       response_parameters: {
  ///         size: 31415
  ///       }
  ///       payload: {
  ///         body: 27182 bytes of zeros
  ///       }
  ///     }
  /// 2. After getting a reply, it sends:
  ///     {
  ///       response_parameters: {
  ///         size: 9
  ///       }
  ///       payload: {
  ///         body: 8 bytes of zeros
  ///       }
  ///     }
  /// 3. After getting a reply, it sends:
  ///     {
  ///       response_parameters: {
  ///         size: 2653
  ///       }
  ///       payload: {
  ///         body: 1828 bytes of zeros
  ///       }
  ///     }
  /// 4. After getting a reply, it sends:
  ///     {
  ///       response_parameters: {
  ///         size: 58979
  ///       }
  ///       payload: {
  ///         body: 45904 bytes of zeros
  ///       }
  ///     }
  /// 5. After getting a reply, client half-closes
  ///
  /// Client asserts:
  /// * call was successful
  /// * exactly four responses
  /// * response payload bodies are sized (in order): 31415, 9, 2653, 58979
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response messages against golden responses
  Future<void> pingPong() async {
    final requestSizes = [27182, 8, 1828, 45904];
    final expectedResponses = [31415, 9, 2653, 58979];

    StreamingOutputCallRequest createRequest(int index) {
      final payload = new Payload()..body = new Uint8List(requestSizes[index]);
      final request = new StreamingOutputCallRequest()
        ..payload = payload
        ..responseParameters
            .add(new ResponseParameters()..size = expectedResponses[index]);
      return request;
    }

    var index = 0;
    final requests = new StreamController<int>();

    final responses = client.fullDuplexCall(requests.stream.map(createRequest));
    requests.add(index);
    await for (final response in responses) {
      if (index >= expectedResponses.length) {
        throw 'Received too many responses. $index > ${expectedResponses.length}.';
      }
      if (response.payload.body.length != expectedResponses[index]) {
        throw 'Response mismatch for response $index: '
            '${response.payload.body.length} != ${expectedResponses[index]}.';
      }
      index++;
      if (index == requestSizes.length) {
        requests.close();
      } else {
        requests.add(index);
      }
    }
  }

  /// This test verifies that streams support having zero-messages in both
  /// directions.
  ///
  /// Procedure:
  /// 1. Client calls FullDuplexCall and then half-closes
  ///
  /// Client asserts:
  /// * call was successful
  /// * exactly zero responses
  Future<void> emptyStream() async {
    final requests = new StreamController<StreamingOutputCallRequest>();
    final call = client.fullDuplexCall(requests.stream);
    requests.close();
    final responses = await call.toList();
    if (responses.length != 0) {
      throw 'Received too many responses. ${responses.length} != 0';
    }
  }

  /// This test is only for cloud-to-prod path.
  ///
  /// This test verifies unary calls succeed in sending messages while using
  /// Service Credentials from GCE metadata server. The client instance needs to
  /// be created with desired oauth scope.
  ///
  /// The test uses `--default_service_account` with GCE service account email
  /// and `--oauth_scope` with the OAuth scope to use. For testing against
  /// grpc-test.sandbox.googleapis.com,
  /// "https://www.googleapis.com/auth/xapi.zoo" should be passed in as
  /// `--oauth_scope`.
  ///
  /// Procedure:
  /// 1. Client configures channel to use GCECredentials
  /// 2. Client calls UnaryCall on the channel with:
  ///     {
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///       fill_username: true
  ///       fill_oauth_scope: true
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * received SimpleResponse.username equals the value of
  ///   `--default_service_account` flag
  /// * received SimpleResponse.oauth_scope is in `--oauth_scope`
  /// * response payload body is 314159 bytes in size
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response message against a golden response
  Future<void> computeEngineCreds() async {
    final credentials = new ComputeEngineAuthenticator();
    final clientWithCredentials =
        new TestServiceClient(channel, options: credentials.toCallOptions);

    final response = await _sendSimpleRequestForAuth(clientWithCredentials,
        fillUsername: true, fillOauthScope: true);

    final user = response.username;
    final oauth = response.oauthScope;

    if (user?.isEmpty ?? true) {
      throw 'Username not received.';
    }
    if (oauth?.isEmpty ?? true) {
      throw 'OAuth scope not received.';
    }

    if (user != defaultServiceAccount) {
      throw 'Got user name $user, wanted $defaultServiceAccount';
    }
    if (!oauthScope.contains(oauth)) {
      throw 'Got OAuth scope $oauth, which is not a substring of $oauthScope';
    }
  }

  /// This test is only for cloud-to-prod path.
  ///
  /// This test verifies unary calls succeed in sending messages while using
  /// service account credentials.
  ///
  /// Test caller should set flag `--service_account_key_file` with the path to
  /// json key file downloaded from https://console.developers.google.com.
  /// Alternately, if using a usable auth implementation, she may specify the
  /// file location in the environment variable GOOGLE_APPLICATION_CREDENTIALS.
  ///
  /// Procedure:
  /// 1. Client configures the channel to use ServiceAccountCredentials
  /// 2. Client calls UnaryCall with:
  ///     {
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///       fill_username: true
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * received SimpleResponse.username is not empty and is in the json key
  ///   file used by the auth library. The client can optionally check the
  ///   username matches the email address in the key file or equals the value
  ///   of `--default_service_account` flag.
  /// * response payload body is 314159 bytes in size
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response message against a golden response
  Future<void> serviceAccountCreds() async {
    throw 'Not implemented';
  }

  /// This test is only for cloud-to-prod path.
  ///
  /// This test verifies unary calls succeed in sending messages while using JWT
  /// token (created by the project's key file)
  ///
  /// Test caller should set flag `--service_account_key_file` with the path to
  /// json key file downloaded from https://console.developers.google.com.
  /// Alternately, if using a usable auth implementation, she may specify the
  /// file location in the environment variable GOOGLE_APPLICATION_CREDENTIALS.
  ///
  /// Procedure:
  /// 1. Client configures the channel to use JWTTokenCredentials
  /// 2. Client calls UnaryCall with:
  ///     {
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///       fill_username: true
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * received SimpleResponse.username is not empty and is in the json key
  ///   file used by the auth library. The client can optionally check the
  ///   username matches the email address in the key file or equals the value
  ///   of `--default_service_account` flag.
  /// * response payload body is 314159 bytes in size
  /// * clients are free to assert that the response payload body contents are
  ///   zero and comparing the entire response message against a golden response
  Future<void> jwtTokenCreds() async {
    final credentials = new JwtServiceAccountAuthenticator(serviceAccountJson);
    final clientWithCredentials =
        new TestServiceClient(channel, options: credentials.toCallOptions);

    final response = await _sendSimpleRequestForAuth(clientWithCredentials,
        fillUsername: true);
    final username = response.username;
    if (username?.isEmpty ?? true) {
      throw 'Username not received.';
    }
    if (!serviceAccountJson.contains(username)) {
      throw 'Got user name $username, which is not a substring of $serviceAccountJson';
    }
  }

  /// This test is only for cloud-to-prod path and some implementations may run
  /// in GCE only.
  ///
  /// This test verifies unary calls succeed in sending messages using an OAuth2
  /// token that is obtained out of band. For the purpose of the test, the
  /// OAuth2 token is actually obtained from a service account credentials or
  /// GCE credentials via the language-specific authorization library.
  ///
  /// The difference between this test and the other auth tests is that it first
  /// uses the authorization library to obtain an authorization token.
  ///
  /// The test
  /// * uses the flag `--service_account_key_file` with the path to a json key
  ///   file downloaded from https://console.developers.google.com. Alternately,
  ///   if using a usable auth implementation, it may specify the file location
  ///   in the environment variable GOOGLE_APPLICATION_CREDENTIALS, *OR* if GCE
  ///   credentials is used to fetch the token, `--default_service_account` can
  ///   be used to pass in GCE service account email.
  /// * uses the flag `--oauth_scope` for the oauth scope. For testing against
  ///   grpc-test.sandbox.googleapis.com,
  ///   "https://www.googleapis.com/auth/xapi.zoo" should be passed as the
  ///   `--oauth_scope`.
  ///
  /// Procedure:
  /// 1. Client uses the auth library to obtain an authorization token
  /// 2. Client configures the channel to use AccessTokenCredentials with the
  ///    access token obtained in step 1
  /// 3. Client calls UnaryCall with the following message
  ///     {
  ///       fill_username: true
  ///       fill_oauth_scope: true
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * received SimpleResponse.username is valid. Depending on whether a
  ///   service account key file or GCE credentials was used, client should
  ///   check against the json key file or GCE default service account email.
  /// * received SimpleResponse.oauth_scope is in `--oauth_scope`
  Future<void> oauth2AuthToken() async {
    final credentials =
        new ServiceAccountAuthenticator(serviceAccountJson, [oauthScope]);
    final clientWithCredentials =
        new TestServiceClient(channel, options: credentials.toCallOptions);

    final response = await _sendSimpleRequestForAuth(clientWithCredentials,
        fillUsername: true, fillOauthScope: true);

    final user = response.username;
    final oauth = response.oauthScope;

    if (user?.isEmpty ?? true) {
      throw 'Username not received.';
    }
    if (oauth?.isEmpty ?? true) {
      throw 'OAuth scope not received.';
    }

    if (!serviceAccountJson.contains(user)) {
      throw 'Got user name $user, which is not a substring of $serviceAccountJson';
    }
    if (!oauthScope.contains(oauth)) {
      throw 'Got OAuth scope $oauth, which is not a substring of $oauthScope';
    }
  }

  /// Similar to the other auth tests, this test is only for cloud-to-prod path.
  ///
  /// This test verifies unary calls succeed in sending messages using a JWT or
  /// a service account credentials set on the RPC.
  ///
  /// The test
  /// * uses the flag `--service_account_key_file` with the path to a json key
  ///   file downloaded from https://console.developers.google.com. Alternately,
  ///   if using a usable auth implementation, it may specify the file location
  ///   in the environment variable GOOGLE_APPLICATION_CREDENTIALS
  /// * optionally uses the flag `--oauth_scope` for the oauth scope if
  ///   implementator wishes to use service account credential instead of JWT
  ///   credential. For testing against grpc-test.sandbox.googleapis.com, oauth
  ///   scope "https://www.googleapis.com/auth/xapi.zoo" should be used.
  ///
  /// Procedure:
  /// 1. Client configures the channel with just SSL credentials
  /// 2. Client calls UnaryCall, setting per-call credentials to
  ///    JWTTokenCredentials. The request is the following message
  ///     {
  ///       fill_username: true
  ///     }
  ///
  /// Client asserts:
  /// * call was successful
  /// * received SimpleResponse.username is not empty and is in the json key
  ///   file used by the auth library. The client can optionally check the
  ///   username matches the email address in the key file.
  Future<void> perRpcCreds() async {
    final credentials =
        new ServiceAccountAuthenticator(serviceAccountJson, [oauthScope]);

    final response = await _sendSimpleRequestForAuth(client,
        fillUsername: true,
        fillOauthScope: true,
        options: credentials.toCallOptions);

    final user = response.username;
    final oauth = response.oauthScope;

    if (user?.isEmpty ?? true) {
      throw 'Username not received.';
    }
    if (oauth?.isEmpty ?? true) {
      throw 'OAuth scope not received.';
    }

    if (!serviceAccountJson.contains(user)) {
      throw 'Got user name $user, which is not a substring of $serviceAccountJson';
    }
    if (!oauthScope.contains(oauth)) {
      throw 'Got OAuth scope $oauth, which is not a substring of $oauthScope';
    }
  }

  Future<SimpleResponse> _sendSimpleRequestForAuth(TestServiceClient client,
      {bool fillUsername: false,
      bool fillOauthScope: false,
      CallOptions options}) async {
    final payload = new Payload()..body = new Uint8List(271828);
    final request = new SimpleRequest()
      ..responseSize = 314159
      ..payload = payload
      ..fillUsername = fillUsername
      ..fillOauthScope = fillOauthScope;
    final response = await client.unaryCall(request, options: options);
    final receivedBytes = response.payload.body.length;
    if (receivedBytes != 314159) {
      throw 'Response payload mismatch. Expected 314159 bytes, '
          'got ${receivedBytes}.';
    }
    return response;
  }

  /// This test verifies that custom metadata in either binary or ascii format
  /// can be sent as initial-metadata by the client and as both initial- and
  /// trailing-metadata by the server.
  ///
  /// Procedure:
  /// 1. The client attaches custom metadata with the following keys and values:
  ///     key: "x-grpc-test-echo-initial", value: "test_initial_metadata_value"
  ///     key: "x-grpc-test-echo-trailing-bin", value: 0xababab
  ///    to a UnaryCall with request:
  ///     {
  ///       response_size: 314159
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  ///
  /// 2. The client attaches custom metadata with the following keys and values:
  ///     key: "x-grpc-test-echo-initial", value: "test_initial_metadata_value"
  ///     key: "x-grpc-test-echo-trailing-bin", value: 0xababab
  ///    to a FullDuplexCall with request:
  ///     {
  ///       response_parameters: {
  ///         size: 314159
  ///       }
  ///       payload: {
  ///         body: 271828 bytes of zeros
  ///       }
  ///     }
  ///    and then half-closes
  ///
  /// Client asserts:
  /// * call was successful
  /// * metadata with key `"x-grpc-test-echo-initial"` and value
  ///   `"test_initial_metadata_value"`is received in the initial metadata for
  ///   calls in Procedure steps 1 and 2.
  /// * metadata with key `"x-grpc-test-echo-trailing-bin"` and value `0xababab`
  ///   is received in the trailing metadata for calls in Procedure steps 1 and
  ///   2.
  Future<void> customMetadata() async {
    void validate(Map<String, String> headers, Map<String, String> trailers) {
      if (headers[_headerEchoKey] != _headerEchoData) {
        throw 'Invalid header data received.';
      }
      if (trailers[_trailerEchoKey] != _trailerEchoData) {
        throw 'Invalid trailer data received.';
      }
    }

    final options = new CallOptions(metadata: {
      _headerEchoKey: _headerEchoData,
      _trailerEchoKey: _trailerEchoData,
    });
    final unaryCall = client.unaryCall(
        new SimpleRequest()
          ..responseSize = 314159
          ..payload = (new Payload()..body = new Uint8List(271828)),
        options: options);
    var headers = await unaryCall.headers;
    var trailers = await unaryCall.trailers;
    await unaryCall;
    validate(headers, trailers);

    Stream<StreamingOutputCallRequest> requests() async* {
      yield new StreamingOutputCallRequest()
        ..responseParameters.add(new ResponseParameters()..size = 314159)
        ..payload = (new Payload()..body = new Uint8List(271828));
    }

    final fullDuplexCall = client.fullDuplexCall(requests(), options: options);
    final drain = fullDuplexCall.drain();
    headers = await fullDuplexCall.headers;
    trailers = await fullDuplexCall.trailers;
    await drain;
    validate(headers, trailers);
  }

  /// This test verifies unary calls succeed in sending messages, and propagate
  /// back status code and message sent along with the messages.
  ///
  /// Procedure:
  /// 1. Client calls UnaryCall with:
  ///     {
  ///       response_status: {
  ///         code: 2
  ///         message: "test status message"
  ///       }
  ///     }
  ///
  /// 2. Client calls FullDuplexCall with:
  ///     {
  ///       response_status: {
  ///         code: 2
  ///         message: "test status message"
  ///       }
  ///     }
  ///
  /// and then half-closes
  ///
  /// Client asserts:
  /// * received status code is the same as the sent code for both Procedure
  ///   steps 1 and 2
  /// * received status message is the same as the sent message for both
  ///   Procedure steps 1 and 2
  Future<void> statusCodeAndMessage() async {
    final expectedStatus = new GrpcError.custom(2, 'test status message');
    final responseStatus = new EchoStatus()
      ..code = expectedStatus.code
      ..message = expectedStatus.message;
    try {
      await client
          .unaryCall(new SimpleRequest()..responseStatus = responseStatus);
      throw 'Did not receive correct status code.';
    } on GrpcError catch (e) {
      if (e != expectedStatus) {
        throw 'Received incorrect status: $e.';
      }
    }
    Stream<StreamingOutputCallRequest> requests() async* {
      yield new StreamingOutputCallRequest()..responseStatus = responseStatus;
    }

    try {
      await for (final _ in client.fullDuplexCall(requests())) {
        throw 'Received unexpected response.';
      }
      throw 'Did not receive correct status code.';
    } on GrpcError catch (e) {
      if (e != expectedStatus) {
        throw 'Received incorrect status: $e.';
      }
    }
  }

  /// This test verifies that calling an unimplemented RPC method returns the
  /// UNIMPLEMENTED status code.
  ///
  /// Procedure:
  /// * Client calls `grpc.testing.TestService/UnimplementedCall` with an empty
  ///   request (defined as `grpc.testing.Empty`):
  ///     {
  ///     }
  ///
  /// Client asserts:
  /// * received status code is 12 (UNIMPLEMENTED)
  Future<void> unimplementedMethod() async {
    try {
      await client.unimplementedCall(new Empty());
      throw 'Did not throw.';
    } on GrpcError catch (e) {
      if (e.code != StatusCode.unimplemented) {
        throw 'Unexpected status code ${e.code} - ${e.message}.';
      }
    }
  }

  /// This test verifies calling an unimplemented server returns the
  /// UNIMPLEMENTED status code.
  ///
  /// Procedure:
  /// * Client calls `grpc.testing.UnimplementedService/UnimplementedCall` with
  ///   an empty request (defined as `grpc.testing.Empty`)
  ///
  /// Client asserts:
  /// * received status code is 12 (UNIMPLEMENTED)
  Future<void> unimplementedService() async {
    try {
      await unimplementedServiceClient.unimplementedCall(new Empty());
      throw 'Did not throw.';
    } on GrpcError catch (e) {
      if (e.code != StatusCode.unimplemented) {
        throw 'Unexpected status code ${e.code} - ${e.message}.';
      }
    }
  }

  /// This test verifies that a request can be cancelled after metadata has been
  /// sent but before payloads are sent.
  ///
  /// Procedure:
  /// 1. Client starts StreamingInputCall
  /// 2. Client immediately cancels request
  ///
  /// Client asserts:
  /// * Call completed with status CANCELLED
  Future<void> cancelAfterBegin() async {
    final requests = new StreamController<StreamingInputCallRequest>();
    final call = client.streamingInputCall(requests.stream);
    scheduleMicrotask(call.cancel);
    try {
      await call;
      throw 'Expected exception.';
    } on GrpcError catch (e) {
      if (e.code != StatusCode.cancelled) {
        throw 'Unexpected status code ${e.code} - ${e.message}';
      }
    }
    requests.close();
  }

  /// This test verifies that a request can be cancelled after receiving a
  /// message from the server.
  ///
  /// Procedure:
  /// 1. Client starts FullDuplexCall with
  ///     {
  ///       response_parameters: {
  ///         size: 31415
  ///       }
  ///       payload: {
  ///         body: 27182 bytes of zeros
  ///       }
  ///     }
  ///
  /// 2. After receiving a response, client cancels request
  ///
  /// Client asserts:
  /// * Call completed with status CANCELLED
  Future<void> cancelAfterFirstResponse() async {
    final requests = new StreamController<StreamingOutputCallRequest>();
    final call = client.fullDuplexCall(requests.stream);
    final completer = new Completer();

    var receivedResponse = false;
    call.listen((response) {
      if (receivedResponse) {
        completer.completeError('Received too many responses.');
        return;
      }
      receivedResponse = true;
      if (response.payload.body.length != 31415) {
        completer.completeError('Invalid response length: '
            '${response.payload.body.length} != 31415.');
      }
      call.cancel();
    }, onError: (e) {
      if (e is! GrpcError) completer.completeError('Unexpected error: $e.');
      if (e.code != StatusCode.cancelled) {
        completer
            .completeError('Unexpected status code ${e.code}: ${e.message}.');
      }
      completer.complete(true);
    }, onDone: () {
      if (!completer.isCompleted) completer.completeError('Expected error.');
    });

    requests.add(new StreamingOutputCallRequest()
      ..responseParameters.add(new ResponseParameters()..size = 31415)
      ..payload = (new Payload()..body = new Uint8List(27182)));
    await completer.future;
    requests.close();
  }

  /// This test verifies that an RPC request whose lifetime exceeds its
  /// configured timeout value will end with the DeadlineExceeded status.
  ///
  /// Procedure:
  /// 1. Client calls FullDuplexCall with the following request and sets its
  ///    timeout to 1ms
  ///     {
  ///       payload: {
  ///         body: 27182 bytes of zeros
  ///       }
  ///     }
  ///
  /// 2. Client waits
  ///
  /// Client asserts:
  /// * Call completed with status DEADLINE_EXCEEDED.
  Future<void> timeoutOnSleepingServer() async {
    final requests = new StreamController<StreamingOutputCallRequest>();
    final call = client.fullDuplexCall(requests.stream,
        options: new CallOptions(timeout: new Duration(milliseconds: 1)));
    requests.add(new StreamingOutputCallRequest()
      ..payload = (new Payload()..body = new Uint8List(27182)));
    try {
      await for (final _ in call) {
        throw 'Unexpected response received.';
      }
      throw 'Expected exception.';
    } on GrpcError catch (e) {
      if (e.code != StatusCode.deadlineExceeded) {
        throw 'Unexpected status code ${e.code} - ${e.message}.';
      }
    } finally {
      requests.close();
    }
  }
}
