// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:ui';

/// Global configuration for route guard fallback behavior.
///
/// This provides a global default fallback path that is used when blocking
/// navigation and no specific fallback is provided.
class RouteGuardConfig {
  RouteGuardConfig._();

  static final RouteGuardConfig _instance = RouteGuardConfig._();

  /// Gets the singleton instance.
  static RouteGuardConfig get instance => _instance;

  String? _fallbackPath;
  String get _defaultFallbackPath =>
      PlatformDispatcher.instance.defaultRouteName;

  /// Gets the current global fallback path.
  String get fallbackPath => _fallbackPath ?? _defaultFallbackPath;

  /// Sets the global fallback path.
  set fallbackPath(String path) => _fallbackPath = path;

  /// Resets the global fallback to the default.
  void reset() => _fallbackPath = null;
}
