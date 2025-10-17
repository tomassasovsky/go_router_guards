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
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res = await guard.executeWithResolver(
        ctx,
        _State(Uri.parse('/cur')),
      );
      expect(res.continueNavigation, isFalse);
      expect(res.redirectPath, '/r');
    });

    testWidgets('RouteGuard.allow factory', (tester) async {
      final guard = RouteGuard.allow();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res = await guard.executeWithResolver(
        ctx,
        _State(Uri.parse('/cur')),
      );
      expect(res.continueNavigation, isTrue);
    });

    testWidgets('RouteGuard.redirectTo factory', (tester) async {
      final guard = RouteGuard.redirectTo('/to');
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res = await guard.executeWithResolver(
        ctx,
        _State(Uri.parse('/cur')),
      );
      expect(res.continueNavigation, isFalse);
      expect(res.redirectPath, '/to');
    });
  });
}

class _State extends Fake implements GoRouterState {
  _State(this._uri);
  final Uri _uri;
  @override
  Uri get uri => _uri;
}
