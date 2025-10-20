import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

class _Allow extends RouteGuard {
  const _Allow();
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    resolver.next();
  }
}

class _Block extends RouteGuard {
  const _Block(this.path);
  final String path;
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    resolver.redirect(path);
  }
}

class _BlockNone extends RouteGuard {
  const _BlockNone();
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    resolver.block();
  }
}

class _NullRedirectGuard extends RouteGuard {
  const _NullRedirectGuard();
  @override
  FutureOr<void> onNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) {
    // No redirect provided; block to current
    resolver.block();
  }
}

class _FakeState extends Fake implements GoRouterState {
  _FakeState(this._uri);
  final Uri _uri;
  @override
  Uri get uri => _uri;
}

void main() {
  group('Guards extensions and redirects', () {
    testWidgets('list extensions build combined guards', (tester) async {
      final all = [const _Allow(), const _Allow()].all();
      final any = [const _Block('/x'), const _Allow()].anyOf();
      final one = [const _Allow(), const _Block('/y')].oneOf();

      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final state = _FakeState(Uri.parse('/z'));

      final allRes = await all.executeWithResolver(ctx, state);
      expect(allRes, isA<AllowResult>());

      final anyRes = await any.executeWithResolver(ctx, state);
      expect(anyRes, isA<AllowResult>());

      final oneRes = await one.executeWithResolver(ctx, state);
      expect(oneRes, isA<AllowResult>());
    });

    testWidgets('iterable redirect builders produce callbacks', (tester) async {
      final redirects = [const _Allow(), const _Block('/b')];

      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));

      final redirectAll = redirects.redirectAll();
      final redirectAny = redirects.redirectAnyOf();
      final redirectOne = redirects.redirectOneOf();

      final resultAll = await redirectAll(ctx, _FakeState(Uri.parse('/a')));
      final resultAny = await redirectAny(ctx, _FakeState(Uri.parse('/a')));
      final resultOne = await redirectOne(ctx, _FakeState(Uri.parse('/a')));

      expect(resultAll, '/b'); // all requires all to pass; blocked by _Block
      expect(resultAny, isNull); // any allows
      expect(resultOne, isNull); // exactly one allows
    });

    testWidgets('anyOf without fallback redirects to first redirect path',
        (tester) async {
      final guard = [const _Block('/a'), const _Block('/b')].anyOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/a');
    });

    testWidgets(
        'oneOf without fallback redirects to first redirect when none pass',
        (tester) async {
      final guard = [const _Block('/x'), const _Block('/y')].oneOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/x');
    });

    testWidgets('anyOf without fallback and no redirect blocks to current path',
        (tester) async {
      final guard = [const _BlockNone(), const _BlockNone()].anyOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/');
    });

    testWidgets('oneOf without fallback and no redirect blocks to current path',
        (tester) async {
      final guard = [const _BlockNone(), const _BlockNone()].oneOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/');
    });

    testWidgets('all() uses block() when a guard fails without redirect',
        (tester) async {
      final guard = [const _Allow(), const _NullRedirectGuard()].all();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/');
    });

    testWidgets(
        'anyOf without fallback uses block() when no guard provides redirect',
        (tester) async {
      final guard =
          [const _NullRedirectGuard(), const _NullRedirectGuard()].anyOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/');
    });

    testWidgets(
        'oneOf without fallback uses block() when zero pass and no redirects',
        (tester) async {
      final guard =
          [const _NullRedirectGuard(), const _NullRedirectGuard()].oneOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/');
    });

    testWidgets('anyOf with empty guards throws ArgumentError', (tester) async {
      final guard = <RouteGuard>[].anyOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));

      expect(
        () => guard.executeWithResolver(ctx, _FakeState(Uri.parse('/test'))),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('oneOf with empty guards throws ArgumentError', (tester) async {
      final guard = <RouteGuard>[].oneOf();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));

      expect(
        () => guard.executeWithResolver(ctx, _FakeState(Uri.parse('/test'))),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('all with empty guards allows navigation', (tester) async {
      final guard = <RouteGuard>[].all();
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<AllowResult>());
    });

    testWidgets('anyOf extension with fallback parameter', (tester) async {
      final guard = [const _Block('/a'), const _Block('/b')]
          .anyOf(fallbackRedirect: '/fallback');
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/fallback');
    });

    testWidgets('oneOf extension with fallback parameter', (tester) async {
      final guard = [const _Block('/x'), const _Block('/y')]
          .oneOf(fallbackRedirect: '/custom');
      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));
      final res =
          await guard.executeWithResolver(ctx, _FakeState(Uri.parse('/cur')));
      expect(res, isA<RedirectResult>());
      expect((res as RedirectResult).path, '/custom');
    });

    testWidgets('redirectAnyOf with fallback parameter', (tester) async {
      final guards = [const _Block('/a'), const _Block('/b')];
      final redirect = guards.redirectAnyOf(fallbackRedirect: '/fallback');

      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));

      final result = await redirect(ctx, _FakeState(Uri.parse('/test')));
      expect(result, '/fallback');
    });

    testWidgets('redirectOneOf with fallback parameter', (tester) async {
      final guards = [const _Block('/x'), const _Block('/y')];
      final redirect = guards.redirectOneOf(fallbackRedirect: '/custom');

      final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => const SizedBox())]);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final ctx = tester.element(find.byType(Navigator));

      final result = await redirect(ctx, _FakeState(Uri.parse('/test')));
      expect(result, '/custom');
    });
  });
}
