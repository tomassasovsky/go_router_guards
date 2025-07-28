/// A flexible and extensible guard system for Go Router that enables type-safe
/// route protection with complex boolean logic support.
///
/// This package provides a powerful expression-based guard system that allows
/// you to:
/// - Create custom route guards with the `RouteGuard` mixin
/// - Combine guards using logical operators (AND, OR, XOR)
/// - Build complex expressions like `(a & b) || c`
/// - Control execution order (left-to-right, right-to-left, parallel)
/// - Use multi-expression operators for multiple guards
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
///   GuardExpression get guards => Guards.and(
///     Guards.guard(AuthenticationGuard()),
///     Guards.guard(RoleGuard(['admin'])),
///   );
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
/// - **Robust Error Handling**: Comprehensive input validation and safe
///   parallel execution
/// - **Customizable Redirects**: Configurable redirect paths for all operators
/// - **Immutable Design**: Safe, predictable behavior
/// - **Extensible Architecture**: Easy to extend and customize
///
/// ## Documentation
///
/// For detailed documentation and examples, see the [README](https://github.com/tomassasovsky/go_router_guards).
library;

export 'src/go_router_guards.dart';
