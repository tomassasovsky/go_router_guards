import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

class _AllowGuard extends RouteGuard {
  const _AllowGuard();
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    resolver.next();
  }
}

@TypedGoRoute<_TRoute>(path: '/t')
class _TRoute extends GoRouteData with GuardedRoute {
  const _TRoute();
  @override
  RouteGuard get guard => const _AllowGuard();
  @override
  Widget build(BuildContext context, GoRouterState state) => const SizedBox();
}

@TypedShellRoute<_TShellRoute>(routes: [])
class _TShellRoute extends ShellRouteData with GuardedShellRoute {
  const _TShellRoute();
  @override
  RouteGuard get guard => const _AllowGuard();
}

class _FakeState extends Fake implements GoRouterState {
  _FakeState(this._uri);
  final Uri _uri;
  @override
  Uri get uri => _uri;
}

void main() {
  testWidgets('GuardedRoute.executeGuard returns null when allowed',
      (tester) async {
    final router = GoRouter(
        routes: [GoRoute(path: '/t', builder: (_, __) => const SizedBox())]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final ctx = tester.element(find.byType(Navigator));
    const route = _TRoute();
    final result = await route.executeGuard(ctx, _FakeState(Uri.parse('/t')));
    expect(result, isNull);
  });

  testWidgets('GuardedShellRoute.executeGuard returns null when allowed',
      (tester) async {
    final router = GoRouter(
        routes: [GoRoute(path: '/t', builder: (_, __) => const SizedBox())]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final ctx = tester.element(find.byType(Navigator));
    const route = _TShellRoute();
    final result = await route.executeGuard(ctx, _FakeState(Uri.parse('/t')));
    expect(result, isNull);
  });

  testWidgets('GuardedRoute.redirect delegates to executeGuard',
      (tester) async {
    final router = GoRouter(
        routes: [GoRoute(path: '/t', builder: (_, __) => const SizedBox())]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final ctx = tester.element(find.byType(Navigator));
    const route = _TRoute();
    final result = await route.redirect(ctx, _FakeState(Uri.parse('/t')));
    expect(result, isNull);
  });

  testWidgets('GuardedShellRoute.redirect delegates to executeGuard',
      (tester) async {
    final router = GoRouter(
        routes: [GoRoute(path: '/t', builder: (_, __) => const SizedBox())]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final ctx = tester.element(find.byType(Navigator));
    const route = _TShellRoute();
    final result = await route.redirect(ctx, _FakeState(Uri.parse('/t')));
    expect(result, isNull);
  });
}
