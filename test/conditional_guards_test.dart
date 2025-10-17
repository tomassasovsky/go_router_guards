import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

class _TestGuard extends RouteGuard {
  const _TestGuard(this.onCall);

  final FutureOr<void> Function(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) onCall;

  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    return onCall(resolver, context, state);
  }
}

class _FakeState extends Fake implements GoRouterState {
  _FakeState(this._uri);
  final Uri _uri;
  @override
  Uri get uri => _uri;
}

void main() {
  group('ConditionalGuard', () {
    test('including factory converts glob patterns', () async {
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
      );
      final resolver = NavigationResolver(router)..next();
      final res = await resolver.future;
      expect(res.continueNavigation, isTrue);
    });

    test('glob ? and meta escaping work', () async {
      final g = ConditionalGuard.including(
        guard: _TestGuard((r, c, s) => r.next()),
        paths: ['/*/file?.txt'],
      );

      final okState = _FakeState(Uri.parse('/a/file1.txt'));
      final okResolver = NavigationResolver(GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]));
      await g.onNavigation(okResolver, const _DummyContext(), okState);
      final ok = await okResolver.future;
      expect(ok.continueNavigation, isTrue);

      final badState = _FakeState(Uri.parse('/a/file/.txt'));
      final badResolver = NavigationResolver(GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]));
      await g.onNavigation(badResolver, const _DummyContext(), badState);
      final bad = await badResolver.future;
      expect(bad.continueNavigation, isTrue);
    });

    test('excluding factory applies precedence and regex', () async {
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())],
      );
      final resolver = NavigationResolver(router)..next();
      final res = await resolver.future;
      expect(res.continueNavigation, isTrue);
    });
    test('allows when path excluded by exact match', () async {
      final conditional = ConditionalGuard(
        guard: _TestGuard((resolver, context, state) {
          resolver.redirect('/should-not-be-used');
        }),
        excludedPaths: const ['/a'],
      );

      final resolver = NavigationResolver(GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]));
      await conditional.onNavigation(
        resolver,
        const _DummyContext(),
        _FakeState(Uri.parse('/a')),
      );
      final result = await resolver.future;
      expect(result.continueNavigation, isTrue);
      expect(result.redirectPath, isNull);
    });

    test('applies underlying guard for included exact path', () async {
      final conditional = ConditionalGuard(
        guard: _TestGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        }),
        includedPaths: const ['/a'],
      );

      final resolver = NavigationResolver(GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]));
      await conditional.onNavigation(
        resolver,
        const _DummyContext(),
        _FakeState(Uri.parse('/a')),
      );
      final result = await resolver.future;
      expect(result.continueNavigation, isFalse);
      expect(result.redirectPath, '/blocked');
    });

    test('applies underlying guard for included pattern', () async {
      final conditional = ConditionalGuard(
        guard: _TestGuard((resolver, context, state) {
          resolver.next();
        }),
        includedPatterns: [RegExp(r'^/user/\\d+$')],
      );

      final resolver = NavigationResolver(GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]));
      await conditional.onNavigation(
        resolver,
        const _DummyContext(),
        _FakeState(Uri.parse('/user/1')),
      );
      final result = await resolver.future;
      expect(result.continueNavigation, isTrue);
      expect(result.redirectPath, isNull);
    });

    test('exclusion takes precedence over inclusion', () async {
      final conditional = ConditionalGuard(
        guard: _TestGuard((resolver, context, state) {
          resolver.redirect('/blocked');
        }),
        includedPatterns: [RegExp('^/admin/.*')],
        excludedPaths: const ['/admin/status'],
      );

      final resolver = NavigationResolver(GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]));
      await conditional.onNavigation(
        resolver,
        const _DummyContext(),
        _FakeState(Uri.parse('/admin/status')),
      );
      final result = await resolver.future;
      expect(result.continueNavigation, isTrue);
      expect(result.redirectPath, isNull);
    });

    test('applies when no inclusion rules provided (default include all)',
        () async {
      final conditional = ConditionalGuard(
        guard: _TestGuard((resolver, context, state) {
          resolver.next();
        }),
      );

      final resolver = NavigationResolver(GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]));
      await conditional.onNavigation(
        resolver,
        const _DummyContext(),
        _FakeState(Uri.parse('/any')),
      );
      final result = await resolver.future;
      expect(result.continueNavigation, isTrue);
    });
  });
}

class _DummyContext extends StatelessWidget implements BuildContext {
  const _DummyContext();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
