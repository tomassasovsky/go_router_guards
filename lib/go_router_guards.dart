/// A flexible and extensible guard system for Go Router that allows you to
/// create middleware-style navigation guards with inclusion and exclusion
/// capabilities.
///
/// ## Features
///
/// - **Route Guards**: Create custom guards that can redirect, block, or
///   allow navigation
/// - **Guard Combinations**: Combine multiple guards with `Guards.all()`,
///   `Guards.anyOf()`, `Guards.oneOf()`
/// - **Conditional Guards**: Apply guards with fine-grained control over
///   which routes are affected
/// - **Inclusion & Exclusion**: Specify exactly which routes should have
///   guards applied
/// - **Type-Safe Integration**: Full support for Go Router's type-safe routing
///   with `GuardedRoute` and `UnguardedRoute` mixins
/// - **Backward Compatibility**: Works with both traditional and type-safe
///   GoRouter configurations
///
/// ## Quick Start
///
/// ### Creating a Guard
/// ```dart
/// class AuthGuard extends RouteGuard {
///   @override
///   FutureOr<void> onNavigation(
///     NavigationResolver resolver,
///     BuildContext context,
///     GoRouterState state,
///   ) async {
///     final isAuthenticated = await checkAuth();
///     if (isAuthenticated) {
///       resolver.next(); // Allow navigation
///     } else {
///       resolver.redirect('/login'); // Redirect to login
///     }
///   }
/// }
/// ```
///
/// ### Conditional Guards with Inclusion
/// ```dart
/// final router = GoRouter(
///   routes: [...],
///   redirect: RouteGuardUtils.createGuardRedirect(
///     ConditionalGuard(
///       guard: AuthGuard(),
///       // Only apply to specific routes
///       includedPatterns: [
///         RegExp(r'^/user/.*'), // All user routes
///         RegExp(r'^/admin/.*'), // All admin routes
///       ],
///       includedPaths: ['/dashboard'], // Specific path
///     ),
///   ),
/// );
/// ```
///
/// ### Conditional Guards with Exclusion
/// ```dart
/// final router = GoRouter(
///   routes: [...],
///   redirect: RouteGuardUtils.createGuardRedirect(
///     ConditionalGuard(
///       guard: AuthGuard(),
///       // Apply to all routes except these
///       excludedPatterns: [RegExp(r'^/public/.*')],
///       excludedPaths: ['/login', '/register'],
///     ),
///   ),
/// );
/// ```
///
/// ### Type-Safe Routes with Guards
/// ```dart
/// @TypedGoRoute<AdminRoute>(path: '/admin')
/// class AdminRoute extends GoRouteData with GuardedRoute {
///   @override
///   RouteGuard get guards => Guards.all([
///     AuthGuard(),
///     RoleGuard(['admin']),
///   ]);
///
///   @override
///   Widget build(context, state) => AdminScreen();
/// }
/// ```
///
/// ### Opting Out of Router-Level Guards
/// ```dart
/// @TypedGoRoute<LoginRoute>(path: '/login')
/// class LoginRoute extends GoRouteData with UnguardedRoute {
///   @override
///   Widget build(context, state) => LoginScreen();
/// }
/// ```
///
/// ## Advanced Features
///
/// ### Inclusion vs Exclusion Logic
///
/// - **Inclusion Rules**: If provided, guards ONLY apply to matching routes
/// - **Exclusion Rules**: If provided, guards apply to all routes EXCEPT
///   matching ones
/// - **Priority**: Exclusion takes precedence over inclusion
/// - **Default**: No inclusion rules means apply to all routes (unless
///   excluded)
///
/// ### Combining Guards
/// ```dart
/// RouteGuard get complexGuard => Guards.all([
///   AuthGuard(),
///   Guards.anyOf([
///     RoleGuard(['admin']),
///     RoleGuard(['moderator']),
///   ]),
/// ]);
/// ```
///
/// ## Migration from Other Guard Systems
///
/// This library is designed to be a drop-in replacement for other guard
/// systems while providing additional flexibility and Go Router integration.
///
library;

export 'src/go_router_guards.dart';
