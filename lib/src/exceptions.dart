// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

/// Base exception for all route guards exceptions.
base class RouteGuardsException implements Exception {
  /// Creates a new [RouteGuardsException].
  const RouteGuardsException();
}

/// Exception thrown when a router is not mounted.
final class RouterNotMountedException extends RouteGuardsException {
  /// Creates a new [RouterNotMountedException].
  const RouterNotMountedException();
}
