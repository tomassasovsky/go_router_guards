import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

void main() {
  group('Shared guards factories', () {
    testWidgets('RouteGuard.from uses callback', (tester) async {
      final guard = RouteGuard.from((resolver, context, state) {
        resolver.redirect('/r');
      });
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res = await guard.executeWithResolver(
        ctx,
        _State(Uri.parse('/cur')),
      );
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/r');
    });

    testWidgets('RouteGuard.allow factory', (tester) async {
      final guard = RouteGuard.allow();
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res = await guard.executeWithResolver(
        ctx,
        _State(Uri.parse('/cur')),
      );
      expect(res, isA<AllowResult>());
    });

    testWidgets('RouteGuard.redirectTo factory', (tester) async {
      final guard = RouteGuard.redirectTo('/to');
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res = await guard.executeWithResolver(
        ctx,
        _State(Uri.parse('/cur')),
      );
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/to');
    });
  });

  testWidgets('RouteGuard.toRedirect returns null when allowed',
      (tester) async {
    final guard = RouteGuard.allow();
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final ctx = tester.element(find.byType(Navigator));
    final redirect = guard.toRedirect();
    final res = await redirect(ctx, _State(Uri.parse('/cur')));
    expect(res, isNull);
  });

  testWidgets('RouteGuard.toRedirect returns path when blocked',
      (tester) async {
    final guard = RouteGuard.redirectTo('/dest');
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final ctx = tester.element(find.byType(Navigator));
    final redirect = guard.toRedirect();
    final res = await redirect(ctx, _State(Uri.parse('/cur')));
    expect(res, '/dest');
  });

  testWidgets('executeWithResolver throws when router not mounted',
      (tester) async {
    // Pump a plain MaterialApp without GoRouter to obtain a BuildContext
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final ctx = tester.element(find.byType(Navigator));

    final guard = RouteGuard.allow();
    expect(
      () => guard.executeWithResolver(
        ctx,
        _State(Uri.parse('/cur')),
      ),
      throwsA(isA<RouterNotMountedException>()),
    );
  });
}

class _State extends Fake implements GoRouterState {
  _State(this._uri);
  final Uri _uri;
  @override
  Uri get uri => _uri;
}
