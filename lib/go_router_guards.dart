/// A flexible and extensible guard system for Go Router that enables type-safe
/// route protection with complex boolean logic support.
///
/// This package provides a powerful guard system that allows you to:
/// - Create custom route guards by implementing the `RouteGuard` class
/// - Combine guards using logical operators (AND, OR, XOR)
/// - Build complex expressions like `(a & b) || c`
/// - Control execution order (sequential, parallel)
/// - Use multi-guard operators for multiple guards
/// - Integrate seamlessly with Go Router's type-safe routes
///
/// ## Quick Start
///
/// ```dart
/// import 'package:go_router_guards/go_router_guards.dart';
///
/// // Create a custom guard
/// class AuthenticationGuard implements RouteGuard {
///   @override
///   FutureOr<String?> redirect(
///     BuildContext context,
///     GoRouterState state,
///   ) async {
///     final authState = context.read<AuthCubit>().state;
///     if (!authState.isAuthenticated) {
///       return '/login';
///     }
///     return null;
///   }
/// }
///
/// // Use with type-safe routes
/// @TypedGoRoute<ProtectedRoute>(path: '/protected')
/// class ProtectedRoute extends GoRouteData with GuardedRoute {
///   const ProtectedRoute();
///
///   @override
///   RouteGuard get guards => Guards.all([
///     AuthenticationGuard(),
///     RoleGuard(['admin']),
///   ]);
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) {
///     return const ProtectedScreen();
///   }
/// }
///
/// // Navigate with type safety
/// ProtectedRoute().go(context);
/// ```
///
/// ## Features
///
/// - **Type-Safe Routes**: Full type safety with Go Router integration
/// - **Complex Boolean Logic**: Support for any boolean expression
/// - **Execution Order Control**: Choose how guards are executed
/// - **Performance Optimized**: Short-circuit evaluation and parallel execution
/// - **Simple API**: Easy to use with minimal boilerplate
library;

export 'src/go_router_guards.dart';
