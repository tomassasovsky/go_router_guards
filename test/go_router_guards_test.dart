import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:go_router_guards/src/multi_operators.dart';
import 'package:mocktail/mocktail.dart';

class MockBuildContext extends Mock implements BuildContext {
  @override
  bool get mounted => true;
}

class MockBuildContextUnmounted extends Mock implements BuildContext {
  @override
  bool get mounted => false;
}

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('go_router_guards', () {
    test('exports RouteGuard interface', () {
      expect(RouteGuard, isNotNull);
    });

    test('exports Guards utility class', () {
      expect(Guards, isNotNull);
    });

    test('exports GuardedRoute mixin', () {
      expect(GuardedRoute, isNotNull);
    });

    test('exports ExecutionOrder enum', () {
      expect(ExecutionOrder, isNotNull);
    });

    group('RouteGuard', () {
      test('can be implemented', () {
        final guard = TestGuard();
        expect(guard, isA<RouteGuard>());
      });

      test('can be used as a mixin', () {
        final guard = TestGuardWithMixin();
        expect(guard, isA<RouteGuard>());
      });

      test('can return null to allow access', () async {
        final guard = TestGuard(() => null);
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await guard.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('can return redirect path to deny access', () async {
        final guard = TestGuard(() => '/login');
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await guard.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });
    });

    group('Guards utility class', () {
      test('throws error for empty all expressions', () {
        expect(
          () => Guards.all([]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for empty anyOf expressions', () {
        expect(
          () => Guards.anyOf([]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for empty oneOf expressions', () {
        expect(
          () => Guards.oneOf([], '/redirect'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for empty redirectPath in oneOf', () {
        final expressions = [TestGuard()];
        expect(
          () => Guards.oneOf(expressions, ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('creates allow expression', () {
        final allow = Guards.allow();
        expect(allow, isA<RouteGuard>());
      });

      test('creates ALL expression', () {
        final expressions = [TestGuard(), TestGuard()];
        final all = Guards.all(expressions);
        expect(all, isA<All>());
      });

      test('creates ANY OF expression', () {
        final expressions = [TestGuard(), TestGuard()];
        final anyOf = Guards.anyOf(expressions);
        expect(anyOf, isA<AnyOf>());
      });

      test('creates ONE OF expression', () {
        final expressions = [TestGuard(), TestGuard()];
        final oneOf = Guards.oneOf(expressions, '/custom');
        expect(oneOf, isA<OneOf>());
      });

      test('allow expression always passes', () async {
        final allow = Guards.allow();
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await allow.redirect(mockContext, mockState);
        expect(result, isNull);
      });
    });

    group('All', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('throws error for empty expressions list', () async {
        final all = All([]);
        expect(
          () => all.redirect(mockContext, mockState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('passes when all expressions pass', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => null),
          TestGuard(() => null),
        ];
        final all = All(expressions);

        final result = await all.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when first expression fails', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => null),
          TestGuard(() => null),
        ];
        final all = All(expressions);

        final result = await all.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('fails when middle expression fails', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => null),
        ];
        final all = All(expressions);

        final result = await all.redirect(mockContext, mockState);
        expect(result, equals('/unauthorized'));
      });

      test('fails when last expression fails', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => null),
          TestGuard(() => '/payment'),
        ];
        final all = All(expressions);

        final result = await all.redirect(mockContext, mockState);
        expect(result, equals('/payment'));
      });

      test('does not execute remaining expressions when one fails', () async {
        var secondExecuted = false;
        var thirdExecuted = false;
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() {
            secondExecuted = true;
            return null;
          }),
          TestGuard(() {
            thirdExecuted = true;
            return null;
          }),
        ];
        final all = All(expressions);

        await all.redirect(mockContext, mockState);
        expect(secondExecuted, isFalse);
        expect(thirdExecuted, isFalse);
      });

      test('executes in sequential order by default', () async {
        final executionOrder = <String>[];
        final expressions = [
          TestGuard(() {
            executionOrder.add('first');
            return null;
          }),
          TestGuard(() {
            executionOrder.add('second');
            return null;
          }),
          TestGuard(() {
            executionOrder.add('third');
            return null;
          }),
        ];
        final all = All(expressions);

        await all.redirect(mockContext, mockState);
        expect(executionOrder, equals(['first', 'second', 'third']));
      });

      test('executes in parallel when specified', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => null),
          TestGuard(() => null),
        ];
        final all = All(expressions, executionOrder: ExecutionOrder.parallel);

        final result = await all.redirect(mockContext, mockState);
        expect(result, isNull);
      });
    });

    group('AnyOf', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('throws error for empty expressions list', () async {
        final anyOf = AnyOf([]);
        expect(
          () => anyOf.redirect(mockContext, mockState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('passes when first expression passes', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final anyOf = AnyOf(expressions);

        final result = await anyOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when middle expression passes', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => null),
          TestGuard(() => '/payment'),
        ];
        final anyOf = AnyOf(expressions);

        final result = await anyOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when last expression passes', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => null),
        ];
        final anyOf = AnyOf(expressions);

        final result = await anyOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when all expressions fail', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final anyOf = AnyOf(expressions);

        final result = await anyOf.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('does not execute remaining expressions when one passes', () async {
        var secondExecuted = false;
        var thirdExecuted = false;
        final expressions = [
          TestGuard(() => null),
          TestGuard(() {
            secondExecuted = true;
            return '/unauthorized';
          }),
          TestGuard(() {
            thirdExecuted = true;
            return '/payment';
          }),
        ];
        final anyOf = AnyOf(expressions);

        await anyOf.redirect(mockContext, mockState);
        expect(secondExecuted, isFalse);
        expect(thirdExecuted, isFalse);
      });

      test('executes in sequential order by default', () async {
        final executionOrder = <String>[];
        final expressions = [
          TestGuard(() {
            executionOrder.add('first');
            return '/login';
          }),
          TestGuard(() {
            executionOrder.add('second');
            return null;
          }),
          TestGuard(() {
            executionOrder.add('third');
            return '/payment';
          }),
        ];
        final anyOf = AnyOf(expressions);

        await anyOf.redirect(mockContext, mockState);
        expect(executionOrder, equals(['first', 'second']));
      });

      test('executes in parallel when specified', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final anyOf =
            AnyOf(expressions, executionOrder: ExecutionOrder.parallel);

        final result = await anyOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when all expressions fail', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final anyOf =
            AnyOf(expressions, executionOrder: ExecutionOrder.parallel);

        final result = await anyOf.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });
    });

    group('OneOf', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('throws error for empty expressions list', () async {
        final oneOf = OneOf([], '/custom');
        expect(
          () => oneOf.redirect(mockContext, mockState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('passes when only first expression passes', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(expressions, '/custom');

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when only second expression passes', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => null),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(expressions, '/custom');

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when only last expression passes', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => null),
        ];
        final oneOf = OneOf(expressions, '/custom');

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when multiple expressions pass', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => null),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(expressions, '/custom');

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, equals('/custom'));
      });

      test('fails when all expressions fail', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(expressions, '/custom');

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('fails when all expressions fail in parallel', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(expressions, '/custom',
            executionOrder: ExecutionOrder.parallel);

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('executes in sequential order by default', () async {
        final executionOrder = <String>[];
        final expressions = [
          TestGuard(() {
            executionOrder.add('first');
            return null;
          }),
          TestGuard(() {
            executionOrder.add('second');
            return '/unauthorized';
          }),
          TestGuard(() {
            executionOrder.add('third');
            return '/payment';
          }),
        ];
        final oneOf = OneOf(
          expressions,
          '/custom',
        );

        await oneOf.redirect(mockContext, mockState);
        expect(executionOrder, equals(['first', 'second', 'third']));
      });

      test('executes in parallel when specified', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when multiple expressions pass', () async {
        final expressions = [
          TestGuard(() => null),
          TestGuard(() => null),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, equals('/custom'));
      });

      test('fails in parallel when all expressions fail', () async {
        final expressions = [
          TestGuard(() => '/login'),
          TestGuard(() => '/unauthorized'),
          TestGuard(() => '/payment'),
        ];
        final oneOf = OneOf(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('short-circuits when multiple expressions pass in sequential order',
          () async {
        var thirdExecuted = false;
        final expressions = [
          TestGuard(() => null), // First passes
          TestGuard(
            () => null,
          ), // Second passes - should trigger short-circuit
          TestGuard(() {
            thirdExecuted = true;
            return '/should-not-execute';
          }),
        ];
        final oneOf = OneOf(
          expressions,
          '/custom',
        );

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, equals('/custom'));
        expect(
          thirdExecuted,
          isFalse,
        ); // Should not execute due to short-circuit
      });

      test('short-circuits when multiple expressions pass in parallel order',
          () async {
        final expressions = [
          TestGuard(() => null), // First passes
          TestGuard(() => null), // Second passes
          TestGuard(() => '/payment'), // Third fails
        ];
        final oneOf = OneOf(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await oneOf.redirect(mockContext, mockState);
        expect(result, equals('/custom'));
      });
    });

    group('GuardedRoute', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('provides default allow guards', () async {
        const route = TestGuardedRoute();
        final result = await route.executeGuards(mockContext, mockState);
        expect(result, isNull);
      });

      test('executes guards on redirect', () async {
        const route = TestGuardedRoute();
        final result = await route.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('can override guards', () {
        const route = TestGuardedRouteWithGuards();
        expect(route.guards, isA<RouteGuard>());
      });

      test('executes custom guards', () async {
        const route = TestGuardedRouteWithGuards();
        final result = await route.redirect(mockContext, mockState);
        expect(result, equals('/custom-redirect'));
      });
    });

    group('Complex expressions', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('(a & b) || c expression', () async {
        final a = TestGuard(() => null); // Pass
        final b = TestGuard(() => null); // Pass
        final c = TestGuard(() => '/c'); // Fail

        final expression = Guards.anyOf([
          Guards.all([a, b]),
          c,
        ]);

        final result = await expression.redirect(mockContext, mockState);
        expect(result, isNull); // (true & true) || false = true
      });

      test('(a & b) || c expression with a failing', () async {
        final a = TestGuard(() => '/a'); // Fail
        final b = TestGuard(() => null); // Pass (not executed)
        final c = TestGuard(() => null); // Pass

        final expression = Guards.anyOf([
          Guards.all([a, b]),
          c,
        ]);

        final result = await expression.redirect(mockContext, mockState);
        expect(result, isNull); // (false & ?) || true = true
      });

      test('(a & b) || c expression with all failing', () async {
        final a = TestGuard(() => '/a'); // Fail
        final b = TestGuard(() => '/b'); // Pass (not executed)
        final c = TestGuard(() => '/c'); // Fail

        final expression = Guards.anyOf([
          Guards.all([a, b]),
          c,
        ]);

        final result = await expression.redirect(mockContext, mockState);
        expect(
          result,
          equals('/a'),
        ); // (false & ?) || false = false, return first
      });
    });
  });
}

// Test implementations
class TestGuard implements RouteGuard {
  TestGuard([this._redirectCallback]);

  final FutureOr<String?> Function()? _redirectCallback;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return _redirectCallback?.call();
  }
}

class TestGuardWithMixin with RouteGuard {
  TestGuardWithMixin([this._redirectCallback]);

  final FutureOr<String?> Function()? _redirectCallback;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    return _redirectCallback?.call();
  }
}

class TestGuardedRoute extends GoRouteData with GuardedRoute {
  const TestGuardedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Scaffold(
      body: Center(child: Text('Test Route')),
    );
  }
}

class TestGuardedRouteWithGuards extends GoRouteData with GuardedRoute {
  const TestGuardedRouteWithGuards();

  @override
  RouteGuard get guards => TestGuard(() => '/custom-redirect');

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Scaffold(
      body: Center(child: Text('Test Route with Guards')),
    );
  }
}
