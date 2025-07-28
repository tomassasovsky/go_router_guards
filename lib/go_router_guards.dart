/// A flexible and extensible guard system for Go Router that allows you to
/// chain multiple guards together for route protection.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:go_router_guards/go_router_guards.dart';
///
/// // Create type-safe routes
/// @TypedGoRoute<LoginRoute>(path: '/login')
/// class LoginRoute extends GoRouteData {
///   const LoginRoute();
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) {
///     return const LoginScreen();
///   }
/// }
///
/// @TypedGoRoute<ProtectedRoute>(path: '/protected')
/// class ProtectedRoute extends GoRouteData with GuardedRoute {
///   const ProtectedRoute();
///
///   @override
///   GuardChain get guards => GuardChain()..add(AuthenticationGuard());
///
///   @override
///   Widget build(BuildContext context, GoRouterState state) {
///     return const ProtectedScreen();
///   }
/// }
///
/// // Create type-safe guards
/// class AuthenticationGuard implements RouteGuard {
///   @override
///   FutureOr<String?> redirect(
///     BuildContext context,
///     GoRouterState state,
///   ) async {
///     final authState = context.read<AuthCubit>().state;
///     if (!authState.isAuthenticated) {
///       return LoginRoute().location; // Type-safe navigation
///     }
///     return null;
///   }
/// }
///
/// // Use type-safe navigation in your UI
/// ElevatedButton(
///   onPressed: () => context.go(ProtectedRoute().location),
///   child: const Text('Go to Protected Route'),
/// )
/// ```
library go_router_guards;

export 'src/go_router_guards.dart';
