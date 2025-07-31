// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_test_app.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$homeRoute];

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/',

  factory: _$HomeRoute._fromState,
  routes: [
    GoRouteData.$route(path: '/login', factory: _$LoginRoute._fromState),
    GoRouteData.$route(
      path: '/factory-guards',

      factory: _$FactoryGuardsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/custom-logic',

      factory: _$CustomLogicRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/conditional/:section',

      factory: _$ConditionalRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/flexible-access',

      factory: _$FlexibleAccessRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/async-guard',

      factory: _$AsyncGuardRoute._fromState,
    ),
    GoRouteData.$route(path: '/blocking', factory: _$BlockingRoute._fromState),
    GoRouteData.$route(path: '/legacy', factory: _$LegacyGuardRoute._fromState),
  ],
);

mixin _$HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) =>
      LoginRoute(redirectTo: state.uri.queryParameters['redirect-to']);

  LoginRoute get _self => this as LoginRoute;

  @override
  String get location => GoRouteData.$location(
    '/login',
    queryParams: {
      if (_self.redirectTo != null) 'redirect-to': _self.redirectTo,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$FactoryGuardsRoute on GoRouteData {
  static FactoryGuardsRoute _fromState(GoRouterState state) =>
      const FactoryGuardsRoute();

  @override
  String get location => GoRouteData.$location('/factory-guards');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$CustomLogicRoute on GoRouteData {
  static CustomLogicRoute _fromState(GoRouterState state) =>
      const CustomLogicRoute();

  @override
  String get location => GoRouteData.$location('/custom-logic');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$ConditionalRoute on GoRouteData {
  static ConditionalRoute _fromState(GoRouterState state) =>
      ConditionalRoute(section: state.pathParameters['section']!);

  ConditionalRoute get _self => this as ConditionalRoute;

  @override
  String get location => GoRouteData.$location(
    '/conditional/${Uri.encodeComponent(_self.section)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$FlexibleAccessRoute on GoRouteData {
  static FlexibleAccessRoute _fromState(GoRouterState state) =>
      const FlexibleAccessRoute();

  @override
  String get location => GoRouteData.$location('/flexible-access');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$AsyncGuardRoute on GoRouteData {
  static AsyncGuardRoute _fromState(GoRouterState state) =>
      const AsyncGuardRoute();

  @override
  String get location => GoRouteData.$location('/async-guard');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$BlockingRoute on GoRouteData {
  static BlockingRoute _fromState(GoRouterState state) => const BlockingRoute();

  @override
  String get location => GoRouteData.$location('/blocking');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$LegacyGuardRoute on GoRouteData {
  static LegacyGuardRoute _fromState(GoRouterState state) =>
      const LegacyGuardRoute();

  @override
  String get location => GoRouteData.$location('/legacy');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
