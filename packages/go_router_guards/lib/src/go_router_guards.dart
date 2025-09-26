// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

// Re-export all core functionality from route_guards
export 'package:route_guards/route_guards.dart';

// Export Go Router specific functionality
export 'go_router_guard.dart' show GoRouterGuard, GoRouterNavigationResolver;
export 'route_guard_utils.dart' show ConditionalGuard, RouteGuardUtils;
export 'route_mixins.dart' show GuardedRoute, GuardedShellRoute, UnguardedRoute;
