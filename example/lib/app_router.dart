// Copyright 2025 Tomás Sasovsky
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:simple_example/guards/auth_guard.dart';
import 'package:simple_example/guards/permission_guard.dart';
import 'package:simple_example/guards/role_guard.dart';
import 'package:simple_example/screens/auth/login_screen.dart';
import 'package:simple_example/screens/auth/unauthorized_screen.dart';
import 'package:simple_example/screens/home/home_screen.dart';
import 'package:simple_example/screens/protected/admin_screen.dart';
import 'package:simple_example/screens/protected/dashboard_screen.dart';
import 'package:simple_example/screens/protected/info_screen.dart';
import 'package:simple_example/screens/protected/premium_screen.dart';
import 'package:simple_example/screens/protected/profile_screen.dart';
import 'package:simple_example/screens/protected/reports_screen.dart';
import 'package:simple_example/screens/protected/secret_info_screen.dart';
import 'package:simple_example/screens/protected/settings_screen.dart';

part 'app_router.g.dart';

/// Root route - public home page
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    // Profile route - requires authentication
    // Demonstrates single guard
    TypedGoRoute<ProfileRoute>(path: 'profile'),

    // Admin route - requires authentication AND admin role
    // Demonstrates guard combination with .all()
    TypedGoRoute<AdminRoute>(path: 'admin'),

    // Premium route - requires authentication AND (premium OR vip role)
    // Demonstrates nested guard combinations
    TypedGoRoute<PremiumRoute>(path: 'premium'),

    // Settings route - requires authentication AND permission
    // Demonstrates permission-based guards
    TypedGoRoute<SettingsRoute>(path: 'settings'),

    // Reports route - accessible by admin OR users with reports permission
    // Demonstrates .anyOf() guard combination
    TypedGoRoute<ReportsRoute>(path: 'reports'),

    // Dashboard - uses async authentication check
    // Demonstrates async guards
    TypedGoRoute<DashboardRoute>(path: 'dashboard'),

    // Info route with nested secret route
    // Demonstrates ConditionalGuard
    TypedGoRoute<InfoRoute>(
      path: 'info',
      routes: [
        TypedGoRoute<SecretInfoRoute>(path: 'secret'),
      ],
    ),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

/// Login route - public
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

/// Unauthorized route - public
@TypedGoRoute<UnauthorizedRoute>(path: '/unauthorized')
class UnauthorizedRoute extends GoRouteData with $UnauthorizedRoute {
  const UnauthorizedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UnauthorizedScreen();
  }
}

/// Profile route - protected by authentication
class ProfileRoute extends GoRouteData with $ProfileRoute, GuardedRoute {
  const ProfileRoute();

  @override
  RouteGuard get guard => const AuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ProfileScreen();
  }
}

/// Admin route - protected by authentication AND admin role
class AdminRoute extends GoRouteData with $AdminRoute, GuardedRoute {
  const AdminRoute();

  @override
  RouteGuard get guard => [
        const AuthGuard(),
        const RoleGuard(['admin']),
      ].all();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const AdminScreen();
  }
}

/// Premium route - protected by authentication AND (premium OR vip role)
class PremiumRoute extends GoRouteData with $PremiumRoute, GuardedRoute {
  const PremiumRoute();

  @override
  RouteGuard get guard => [
        const AuthGuard(),
        [
          const RoleGuard(['premium']),
          const RoleGuard(['vip']),
        ].anyOf(),
      ].all();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PremiumScreen();
  }
}

/// Settings route - protected by authentication AND permission
class SettingsRoute extends GoRouteData with $SettingsRoute, GuardedRoute {
  const SettingsRoute();

  @override
  RouteGuard get guard => [
        const AuthGuard(),
        const PermissionGuard('view_settings'),
      ].all();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}

/// Reports route - protected by authentication AND (admin role OR permission)
class ReportsRoute extends GoRouteData with $ReportsRoute, GuardedRoute {
  const ReportsRoute();

  @override
  RouteGuard get guard => [
        const AuthGuard(),
        [
          const RoleGuard(['admin']),
          const PermissionGuard('view_reports'),
        ].anyOf(fallbackRedirect: '/unauthorized'),
      ].all();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ReportsScreen();
  }
}

/// Dashboard route - protected by async authentication
class DashboardRoute extends GoRouteData with $DashboardRoute, GuardedRoute {
  const DashboardRoute();

  @override
  RouteGuard get guard => const AsyncAuthGuard();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DashboardScreen();
  }
}

/// Info route - public
class InfoRoute extends GoRouteData with $InfoRoute {
  const InfoRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const InfoScreen();
  }
}

/// Secret info route - protected by conditional guard
class SecretInfoRoute extends GoRouteData with $SecretInfoRoute, GuardedRoute {
  const SecretInfoRoute();

  @override
  RouteGuard get guard => ConditionalGuard.including(
        guard: const AuthGuard(),
        paths: ['/info/secret'],
      );

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SecretInfoScreen();
  }
}

/// Application router configuration showcasing various guard use cases
final router = GoRouter(
  initialLocation: '/',
  routes: $appRoutes,
);
