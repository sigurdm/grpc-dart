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
import 'dart:math';

const defaultIdleTimeout = const Duration(minutes: 5);

typedef Duration BackoffStrategy(Duration lastBackoff);

// Backoff algorithm from https://github.com/grpc/grpc/blob/master/doc/connection-backoff.md
const _initialBackoff = const Duration(seconds: 1);
const _maxBackoff = const Duration(seconds: 120);
const _multiplier = 1.6;
const _jitter = 0.2;
final _random = new Random();

Duration defaultBackoffStrategy(Duration lastBackoff) {
  if (lastBackoff == null) return _initialBackoff;
  final jitter = _random.nextDouble() * 2 * _jitter - _jitter;
  final nextBackoff = lastBackoff * (_multiplier + jitter);
  return nextBackoff < _maxBackoff ? nextBackoff : _maxBackoff;
}

/// Options controlling how connections are made on a [ClientChannel].
class ChannelOptions {
  final Duration idleTimeout;
  final BackoffStrategy backoffStrategy;

  const ChannelOptions({
    this.idleTimeout = defaultIdleTimeout,
    this.backoffStrategy = defaultBackoffStrategy,
  });
}

/// Provides per-RPC metadata.
///
/// Metadata providers will be invoked for every RPC, and can add their own
/// metadata to the RPC. If the function returns a [Future], the RPC will await
/// completion of the returned [Future] before transmitting the request.
///
/// The metadata provider is given the current [metadata] map (possibly modified
/// by previous metadata providers) and the [uri] that is being called, and is
/// expected to modify the map before returning or before completing the
/// returned [Future].
typedef FutureOr<void> MetadataProvider(
    Map<String, String> metadata, String uri);

/// Runtime options for an RPC.
class CallOptions {
  final Map<String, String> metadata;
  final Duration timeout;
  final List<MetadataProvider> metadataProviders;

  CallOptions._(this.metadata, this.timeout, this.metadataProviders);

  /// Creates a [CallOptions] object.
  ///
  /// [CallOptions] can specify static [metadata], set the [timeout], and
  /// configure per-RPC metadata [providers]. The metadata [providers] are
  /// invoked in order for every RPC, and can modify the outgoing metadata
  /// (including metadata provided by previous providers).
  factory CallOptions(
      {Map<String, String> metadata,
      Duration timeout,
      List<MetadataProvider> providers}) {
    return new CallOptions._(new Map.unmodifiable(metadata ?? {}), timeout,
        new List.unmodifiable(providers ?? []));
  }

  factory CallOptions.from(Iterable<CallOptions> options) =>
      options.fold(new CallOptions(), (p, o) => p.mergedWith(o));

  CallOptions mergedWith(CallOptions other) {
    if (other == null) return this;
    final mergedMetadata = new Map.from(metadata)..addAll(other.metadata);
    final mergedTimeout = other.timeout ?? timeout;
    final mergedProviders = new List.from(metadataProviders)
      ..addAll(other.metadataProviders);
    return new CallOptions._(new Map.unmodifiable(mergedMetadata),
        mergedTimeout, new List.unmodifiable(mergedProviders));
  }
}
