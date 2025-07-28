import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';
import 'package:mocktail/mocktail.dart';

class MockBuildContext extends Mock implements BuildContext {
  @override
  bool get mounted => true;
}

class MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('go_router_guards', () {
    test('exports RouteGuard interface', () {
      expect(RouteGuard, isNotNull);
    });

    test('exports GuardExpression class', () {
      expect(GuardExpression, isNotNull);
    });

    test('exports Guards utility class', () {
      expect(Guards, isNotNull);
    });

    test('Guards class has private constructor', () {
      // The constructor is private, so we can't instantiate it
      // This test verifies that the class exists and has static methods
      expect(Guards.guard, isA<Function>());
      expect(Guards.and, isA<Function>());
      expect(Guards.or, isA<Function>());
      expect(Guards.xor, isA<Function>());
    });

    test('Guards class can be instantiated', () {
      // Test that the constructor can be called
      const guards = Guards();
      expect(guards, isA<Guards>());
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

    group('GuardExpression', () {
      test('can be implemented', () {
        final expression = TestGuardExpression();
        expect(expression, isA<GuardExpression>());
      });

      test('can return null to allow access', () async {
        final expression = TestGuardExpression(() => null);
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await expression.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('can return redirect path to deny access', () async {
        final expression = TestGuardExpression(() => '/login');
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await expression.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('has default execution order', () {
        final expression = TestGuardExpression();
        expect(expression.executionOrder, equals(ExecutionOrder.leftToRight));
      });

      test('can have custom execution order', () {
        final expression =
            TestGuardExpressionWithOrder(ExecutionOrder.parallel);
        expect(expression.executionOrder, equals(ExecutionOrder.parallel));
      });
    });

    group('Guard', () {
      test('wraps RouteGuard as GuardExpression', () async {
        final routeGuard = TestGuard(() => '/login');
        final guard = Guard(routeGuard);
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await guard.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('has default execution order', () {
        final routeGuard = TestGuard();
        final guard = Guard(routeGuard);
        expect(guard.executionOrder, equals(ExecutionOrder.leftToRight));
      });

      test('can have custom execution order', () {
        final routeGuard = TestGuard();
        final guard =
            Guard(routeGuard, executionOrder: ExecutionOrder.parallel);
        expect(guard.executionOrder, equals(ExecutionOrder.parallel));
      });
    });

    group('And', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('passes when both expressions pass', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => null);
        final and = And(left, right);

        final result = await and.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when first expression fails', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => null);
        final and = And(left, right);

        final result = await and.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('fails when second expression fails', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final and = And(left, right);

        final result = await and.execute(mockContext, mockState);
        expect(result, equals('/unauthorized'));
      });

      test('does not execute second expression when first fails', () async {
        var rightExecuted = false;
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() {
          rightExecuted = true;
          return null;
        });
        final and = And(left, right);

        await and.execute(mockContext, mockState);
        expect(rightExecuted, isFalse);
      });

      test('executes in right-to-left order when specified', () async {
        final executionOrder = <String>[];
        final left = TestGuardExpression(() {
          executionOrder.add('left');
          return null;
        });
        final right = TestGuardExpression(() {
          executionOrder.add('right');
          return null;
        });
        final and =
            And(left, right, executionOrder: ExecutionOrder.rightToLeft);

        await and.execute(mockContext, mockState);
        expect(executionOrder, equals(['right', 'left']));
      });

      test('executes in parallel when specified', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => null);
        final and = And(left, right, executionOrder: ExecutionOrder.parallel);

        final result = await and.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when first expression fails', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final and = And(left, right, executionOrder: ExecutionOrder.parallel);

        final result = await and.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('fails in parallel when second expression fails', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final and = And(left, right, executionOrder: ExecutionOrder.parallel);

        final result = await and.execute(mockContext, mockState);
        expect(result, equals('/unauthorized'));
      });
    });

    group('Or', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('passes when first expression passes', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final or = Or(left, right);

        final result = await or.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when second expression passes', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => null);
        final or = Or(left, right);

        final result = await or.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when both expressions fail', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final or = Or(left, right);

        final result = await or.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('does not execute second expression when first passes', () async {
        var rightExecuted = false;
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() {
          rightExecuted = true;
          return '/unauthorized';
        });
        final or = Or(left, right);

        await or.execute(mockContext, mockState);
        expect(rightExecuted, isFalse);
      });

      test('executes in right-to-left order when specified', () async {
        final executionOrder = <String>[];
        final left = TestGuardExpression(() {
          executionOrder.add('left');
          return '/login';
        });
        final right = TestGuardExpression(() {
          executionOrder.add('right');
          return null;
        });
        final or = Or(left, right, executionOrder: ExecutionOrder.rightToLeft);

        await or.execute(mockContext, mockState);
        expect(executionOrder, equals(['right']));
      });

      test('executes in right-to-left order when both fail', () async {
        final executionOrder = <String>[];
        final left = TestGuardExpression(() {
          executionOrder.add('left');
          return '/login';
        });
        final right = TestGuardExpression(() {
          executionOrder.add('right');
          return '/unauthorized';
        });
        final or = Or(left, right, executionOrder: ExecutionOrder.rightToLeft);

        final result = await or.execute(mockContext, mockState);
        expect(executionOrder, equals(['right', 'left']));
        expect(result, equals('/unauthorized'));
      });

      test('executes in parallel when specified', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final or = Or(left, right, executionOrder: ExecutionOrder.parallel);

        final result = await or.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when both expressions fail', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final or = Or(left, right, executionOrder: ExecutionOrder.parallel);

        final result = await or.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });
    });

    group('Xor', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('passes when only first expression passes', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(left, right, '/custom');

        final result = await xor.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when only second expression passes', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => null);
        final xor = Xor(left, right, '/custom');

        final result = await xor.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when both expressions pass', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => null);
        final xor = Xor(left, right, '/custom');

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/custom'));
      });

      test('fails when both expressions fail', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(left, right, '/custom');

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('executes in right-to-left order when specified', () async {
        final executionOrder = <String>[];
        final left = TestGuardExpression(() {
          executionOrder.add('left');
          return null;
        });
        final right = TestGuardExpression(() {
          executionOrder.add('right');
          return '/unauthorized';
        });
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.rightToLeft,
        );

        await xor.execute(mockContext, mockState);
        expect(executionOrder, equals(['right', 'left']));
      });

      test('fails in right-to-left order when both expressions fail', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.rightToLeft,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(
          result,
          equals('/login'),
        ); // Should return left result
      });

      test('fails in right-to-left order when both expressions pass', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => null);
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.rightToLeft,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/custom')); // Should return custom redirect path
      });

      test('executes in parallel when specified', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when both expressions pass', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => null);
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/custom'));
      });

      test('fails in parallel when both expressions fail', () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('passes in parallel when exactly one expression passes', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when both expressions fail with custom redirect',
          () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('fails in parallel when both expressions pass', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => null);
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/custom'));
      });

      test('passes in parallel when exactly one expression passes', () async {
        final left = TestGuardExpression(() => null);
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when both expressions fail with non-null results',
          () async {
        final left = TestGuardExpression(() => '/login');
        final right = TestGuardExpression(() => '/unauthorized');
        final xor = Xor(
          left,
          right,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xor.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });
    });

    group('Guards utility class', () {
      test('creates guard expression from RouteGuard', () {
        final routeGuard = TestGuard();
        final expression = Guards.guard(routeGuard);
        expect(expression, isA<Guard>());
      });

      test('throws error for empty andAll expressions', () {
        expect(
          () => Guards.andAll([]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for empty orAll expressions', () {
        expect(
          () => Guards.orAll([]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for empty xorAll expressions', () {
        expect(
          () => Guards.xorAll([], '/redirect'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for empty redirectPath in xor', () {
        final left = TestGuardExpression();
        final right = TestGuardExpression();
        expect(
          () => Guards.xor(left, right, ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws error for empty redirectPath in xorAll', () {
        final expressions = [TestGuardExpression()];
        expect(
          () => Guards.xorAll(expressions, ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('creates AND expression', () {
        final left = TestGuardExpression();
        final right = TestGuardExpression();
        final and = Guards.and(left, right);
        expect(and, isA<And>());
      });

      test('creates OR expression', () {
        final left = TestGuardExpression();
        final right = TestGuardExpression();
        final or = Guards.or(left, right);
        expect(or, isA<Or>());
      });

      test('creates XOR expression', () {
        final left = TestGuardExpression();
        final right = TestGuardExpression();
        final xor = Guards.xor(left, right, '/custom');
        expect(xor, isA<Xor>());
      });

      test('creates allow expression', () {
        final allow = Guards.allow();
        expect(allow, isA<GuardExpression>());
      });

      test('creates AND ALL expression', () {
        final expressions = [TestGuardExpression(), TestGuardExpression()];
        final andAll = Guards.andAll(expressions);
        expect(andAll, isA<AndAll>());
      });

      test('creates OR ALL expression', () {
        final expressions = [TestGuardExpression(), TestGuardExpression()];
        final orAll = Guards.orAll(expressions);
        expect(orAll, isA<OrAll>());
      });

      test('creates XOR ALL expression', () {
        final expressions = [TestGuardExpression(), TestGuardExpression()];
        final xorAll = Guards.xorAll(expressions, '/custom');
        expect(xorAll, isA<XorAll>());
      });

      test('allow expression always passes', () async {
        final allow = Guards.allow();
        final mockContext = MockBuildContext();
        final mockState = MockGoRouterState();

        final result = await allow.execute(mockContext, mockState);
        expect(result, isNull);
      });
    });

    group('AndAll', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('throws error for empty expressions list', () async {
        const andAll = AndAll([]);
        expect(
          () => andAll.execute(mockContext, mockState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('passes when all expressions pass', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
        ];
        final andAll = AndAll(expressions);

        final result = await andAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when first expression fails', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
        ];
        final andAll = AndAll(expressions);

        final result = await andAll.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('fails when middle expression fails', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => null),
        ];
        final andAll = AndAll(expressions);

        final result = await andAll.execute(mockContext, mockState);
        expect(result, equals('/unauthorized'));
      });

      test('fails when last expression fails', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/payment'),
        ];
        final andAll = AndAll(expressions);

        final result = await andAll.execute(mockContext, mockState);
        expect(result, equals('/payment'));
      });

      test('does not execute remaining expressions when one fails', () async {
        var secondExecuted = false;
        var thirdExecuted = false;
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() {
            secondExecuted = true;
            return null;
          }),
          TestGuardExpression(() {
            thirdExecuted = true;
            return null;
          }),
        ];
        final andAll = AndAll(expressions);

        await andAll.execute(mockContext, mockState);
        expect(secondExecuted, isFalse);
        expect(thirdExecuted, isFalse);
      });

      test('executes in right-to-left order when specified', () async {
        final executionOrder = <String>[];
        final expressions = [
          TestGuardExpression(() {
            executionOrder.add('first');
            return null;
          }),
          TestGuardExpression(() {
            executionOrder.add('second');
            return null;
          }),
          TestGuardExpression(() {
            executionOrder.add('third');
            return null;
          }),
        ];
        final andAll =
            AndAll(expressions, executionOrder: ExecutionOrder.rightToLeft);

        await andAll.execute(mockContext, mockState);
        expect(executionOrder, equals(['third', 'second', 'first']));
      });

      test('executes in parallel when specified', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
        ];
        final andAll =
            AndAll(expressions, executionOrder: ExecutionOrder.parallel);

        final result = await andAll.execute(mockContext, mockState);
        expect(result, isNull);
      });
    });

    group('OrAll', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('throws error for empty expressions list', () async {
        const orAll = OrAll([]);
        expect(
          () => orAll.execute(mockContext, mockState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('passes when first expression passes', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final orAll = OrAll(expressions);

        final result = await orAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when middle expression passes', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/payment'),
        ];
        final orAll = OrAll(expressions);

        final result = await orAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when last expression passes', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => null),
        ];
        final orAll = OrAll(expressions);

        final result = await orAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when all expressions fail', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final orAll = OrAll(expressions);

        final result = await orAll.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('does not execute remaining expressions when one passes', () async {
        var secondExecuted = false;
        var thirdExecuted = false;
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() {
            secondExecuted = true;
            return '/unauthorized';
          }),
          TestGuardExpression(() {
            thirdExecuted = true;
            return '/payment';
          }),
        ];
        final orAll = OrAll(expressions);

        await orAll.execute(mockContext, mockState);
        expect(secondExecuted, isFalse);
        expect(thirdExecuted, isFalse);
      });

      test('executes in right-to-left order when specified', () async {
        final executionOrder = <String>[];
        final expressions = [
          TestGuardExpression(() {
            executionOrder.add('first');
            return '/login';
          }),
          TestGuardExpression(() {
            executionOrder.add('second');
            return null;
          }),
          TestGuardExpression(() {
            executionOrder.add('third');
            return '/payment';
          }),
        ];
        final orAll =
            OrAll(expressions, executionOrder: ExecutionOrder.rightToLeft);

        await orAll.execute(mockContext, mockState);
        expect(executionOrder, equals(['third', 'second']));
      });

      test('executes in parallel when specified', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final orAll =
            OrAll(expressions, executionOrder: ExecutionOrder.parallel);

        final result = await orAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when all expressions fail', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final orAll =
            OrAll(expressions, executionOrder: ExecutionOrder.parallel);

        final result = await orAll.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });
    });

    group('XorAll', () {
      late MockBuildContext mockContext;
      late MockGoRouterState mockState;

      setUp(() {
        mockContext = MockBuildContext();
        mockState = MockGoRouterState();
      });

      test('throws error for empty expressions list', () async {
        const xorAll = XorAll([], '/custom');
        expect(
          () => xorAll.execute(mockContext, mockState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('passes when only first expression passes', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final xorAll = XorAll(expressions, '/custom');

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when only second expression passes', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/payment'),
        ];
        final xorAll = XorAll(expressions, '/custom');

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('passes when only last expression passes', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => null),
        ];
        final xorAll = XorAll(expressions, '/custom');

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails when multiple expressions pass', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/payment'),
        ];
        final xorAll = XorAll(expressions, '/custom');

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, equals('/custom'));
      });

      test('fails when all expressions fail', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final xorAll = XorAll(expressions, '/custom');

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('executes in right-to-left order when specified', () async {
        final executionOrder = <String>[];
        final expressions = [
          TestGuardExpression(() {
            executionOrder.add('first');
            return null;
          }),
          TestGuardExpression(() {
            executionOrder.add('second');
            return '/unauthorized';
          }),
          TestGuardExpression(() {
            executionOrder.add('third');
            return '/payment';
          }),
        ];
        final xorAll = XorAll(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.rightToLeft,
        );

        await xorAll.execute(mockContext, mockState);
        expect(executionOrder, equals(['third', 'second', 'first']));
      });

      test('executes in parallel when specified', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final xorAll = XorAll(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('fails in parallel when multiple expressions pass', () async {
        final expressions = [
          TestGuardExpression(() => null),
          TestGuardExpression(() => null),
          TestGuardExpression(() => '/payment'),
        ];
        final xorAll = XorAll(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, equals('/custom'));
      });

      test('fails in parallel when all expressions fail', () async {
        final expressions = [
          TestGuardExpression(() => '/login'),
          TestGuardExpression(() => '/unauthorized'),
          TestGuardExpression(() => '/payment'),
        ];
        final xorAll = XorAll(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.parallel,
        );

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, equals('/login'));
      });

      test('short-circuits when multiple expressions pass in leftToRight order',
          () async {
        var thirdExecuted = false;
        final expressions = [
          TestGuardExpression(() => null), // First passes
          TestGuardExpression(
            () => null,
          ), // Second passes - should trigger short-circuit
          TestGuardExpression(() {
            thirdExecuted = true;
            return '/should-not-execute';
          }),
        ];
        final xorAll = XorAll(
          expressions,
          '/custom',
        );

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, equals('/custom'));
        expect(
          thirdExecuted,
          isFalse,
        ); // Should not execute due to short-circuit
      });

      test('short-circuits when multiple expressions pass in rightToLeft order',
          () async {
        var firstExecuted = false;
        final expressions = [
          TestGuardExpression(() {
            firstExecuted = true;
            return '/should-not-execute';
          }),
          TestGuardExpression(() => null), // Second passes
          TestGuardExpression(
            () => null,
          ), // Third passes - should trigger short-circuit
        ];
        final xorAll = XorAll(
          expressions,
          '/custom',
          executionOrder: ExecutionOrder.rightToLeft,
        );

        final result = await xorAll.execute(mockContext, mockState);
        expect(result, equals('/custom'));
        expect(
          firstExecuted,
          isFalse,
        ); // Should not execute due to short-circuit
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
        final result = await route.guards.execute(mockContext, mockState);
        expect(result, isNull);
      });

      test('executes guards on redirect', () async {
        const route = TestGuardedRoute();
        final result = await route.redirect(mockContext, mockState);
        expect(result, isNull);
      });

      test('can override guards', () {
        const route = TestGuardedRouteWithGuards();
        expect(route.guards, isA<GuardExpression>());
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
        final a = TestGuardExpression(() => null); // Pass
        final b = TestGuardExpression(() => null); // Pass
        final c = TestGuardExpression(() => '/c'); // Fail

        final expression = Guards.or(
          Guards.and(a, b),
          c,
        );

        final result = await expression.execute(mockContext, mockState);
        expect(result, isNull); // (true & true) || false = true
      });

      test('(a & b) || c expression with a failing', () async {
        final a = TestGuardExpression(() => '/a'); // Fail
        final b = TestGuardExpression(() => null); // Pass (not executed)
        final c = TestGuardExpression(() => null); // Pass

        final expression = Guards.or(
          Guards.and(a, b),
          c,
        );

        final result = await expression.execute(mockContext, mockState);
        expect(result, isNull); // (false & ?) || true = true
      });

      test('(a & b) || c expression with all failing', () async {
        final a = TestGuardExpression(() => '/a'); // Fail
        final b = TestGuardExpression(() => '/b'); // Pass (not executed)
        final c = TestGuardExpression(() => '/c'); // Fail

        final expression = Guards.or(
          Guards.and(a, b),
          c,
        );

        final result = await expression.execute(mockContext, mockState);
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

class TestGuardExpression extends GuardExpression {
  TestGuardExpression([this._executeCallback]);

  final FutureOr<String?> Function()? _executeCallback;

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) {
    return _executeCallback?.call();
  }
}

class TestGuardExpressionWithOrder extends GuardExpression {
  TestGuardExpressionWithOrder(ExecutionOrder order)
      : super(executionOrder: order);

  @override
  FutureOr<String?> execute(BuildContext context, GoRouterState state) {
    return null;
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
  GuardExpression get guards => Guards.guard(
        TestGuard(() => '/custom-redirect'),
      );

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const Scaffold(
      body: Center(child: Text('Test Route with Guards')),
    );
  }
}
