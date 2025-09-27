---
title: Multi-Layer Protection
description: Implement sophisticated multi-layer security with router-level, shell-level, and route-level guards
---

import { Steps, Tabs, TabItem } from '@astrojs/starlight/components';

This example demonstrates how to implement a comprehensive multi-layer security system that provides defense in depth through router-level, shell-level, and route-level protection.

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                Router Level                     │
│  • Global authentication                       │
│  • Basic security policies                     │
│  • Public route exclusions                     │
└─────────────────────────────────────────────────┘
                        │
┌─────────────────────────────────────────────────┐
│                Shell Level                      │
│  • Area-specific authorization                 │
│  • Context validation                          │
│  • Session verification                        │
└─────────────────────────────────────────────────┘
                        │
┌─────────────────────────────────────────────────┐
│                Route Level                      │
│  • Fine-grained permissions                    │
│  • Resource-specific access                    │
│  • Dynamic rule enforcement                    │
└─────────────────────────────────────────────────┘
```

## Security Layer Implementation

### Layer 1: Router-Level Security

```dart
// lib/security/router_security.dart
import 'package:go_router/go_router.dart';
import 'package:go_router_guards/go_router_guards.dart';

class RouterSecurity {
  static GoRouterRedirect createGlobalSecurityRedirect() {
    return RouteGuardUtils.createGuardRedirect(
      ConditionalGuard(
        guard: Guards.all([
          GlobalSecurityGuard(),
          BasicAuthenticationGuard(),
          SecurityPolicyGuard(),
        ]),
        excludedPaths: _getPublicPaths(),
      ),
    );
  }

  static List<String> _getPublicPaths() => [
    '/',
    '/login',
    '/register',
    '/forgot-password',
    '/privacy',
    '/terms',
    '/public',
    '/health',
    '/error',
  ];
}

class GlobalSecurityGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    // Global security checks
    
    // 1. Check if application is in maintenance mode
    if (await configService.isMaintenanceMode()) {
      final user = getCurrentUser(context);
      if (user?.hasRole('admin') != true) {
        resolver.redirect('/maintenance');
        return;
      }
    }

    // 2. Rate limiting check
    final clientId = await getClientId(context);
    if (await rateLimitService.isRateLimited(clientId)) {
      resolver.redirect('/rate-limited');
      return;
    }

    // 3. IP allowlist check (for sensitive operations)
    if (_isSensitivePath(state.uri.path)) {
      final isAllowedIP = await securityService.isIPAllowed(
        await getClientIP(context),
      );
      if (!isAllowedIP) {
        resolver.redirect('/access-denied');
        return;
      }
    }

    // 4. Device verification for high-security paths
    if (_isHighSecurityPath(state.uri.path)) {
      final isDeviceVerified = await deviceService.isDeviceVerified(
        await getDeviceId(context),
      );
      if (!isDeviceVerified) {
        resolver.redirect('/device-verification');
        return;
      }
    }

    resolver.next();
  }

  bool _isSensitivePath(String path) {
    const sensitivePaths = ['/admin', '/api', '/system'];
    return sensitivePaths.any(path.startsWith);
  }

  bool _isHighSecurityPath(String path) {
    const highSecurityPaths = ['/financial', '/user-data', '/admin/system'];
    return highSecurityPaths.any(path.startsWith);
  }
}

class SecurityPolicyGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.next(); // Let auth guard handle this
      return;
    }

    // Check password expiry
    if (await authService.isPasswordExpired(user.id)) {
      resolver.redirect('/change-password?expired=true');
      return;
    }

    // Check terms acceptance
    if (!await userService.hasAcceptedLatestTerms(user.id)) {
      resolver.redirect('/accept-terms');
      return;
    }

    // Check security questions setup
    if (await securityService.requiresSecurityQuestions(user.id)) {
      resolver.redirect('/setup-security-questions');
      return;
    }

    // Check suspicious activity
    if (await securityService.hasSuspiciousActivity(user.id)) {
      resolver.redirect('/security-verification');
      return;
    }

    resolver.next();
  }
}
```

### Layer 2: Shell-Level Security

```dart
// lib/security/shell_security.dart

// Admin Shell Security
@TypedShellRoute<AdminShellRoute>(
  routes: [
    TypedGoRoute<AdminDashboardRoute>(path: '/dashboard'),
    TypedGoRoute<AdminUsersRoute>(path: '/users'),
    TypedGoRoute<AdminSystemRoute>(path: '/system'),
    TypedGoRoute<AdminSecurityRoute>(path: '/security'),
  ],
)
class AdminShellRoute extends ShellRouteData with GuardedShellRoute {
  @override
  RouteGuard get guards => Guards.all([
    AdminAccessGuard(),
    AdminSessionGuard(),
    AdminAuditGuard(),
  ]);

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget child) {
    return AdminLayout(
      currentPath: state.uri.path,
      child: child,
    );
  }
}

class AdminAccessGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.redirect('/login?returnUrl=${Uri.encodeComponent(state.uri.toString())}');
      return;
    }

    // Multi-factor authentication for admin area
    if (!await mfaService.isVerified(user.id)) {
      resolver.redirect('/mfa-verification?returnUrl=${Uri.encodeComponent(state.uri.toString())}');
      return;
    }

    // Admin role verification
    if (!user.hasRole('admin')) {
      await securityService.logUnauthorizedAccess(
        userId: user.id,
        attemptedPath: state.uri.path,
        reason: 'insufficient_role',
      );
      resolver.redirect('/unauthorized');
      return;
    }

    // Time-based restrictions
    if (!await scheduleService.isAdminAccessAllowed()) {
      resolver.redirect('/admin-hours-restricted');
      return;
    }

    resolver.next();
  }
}

class AdminSessionGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }

    // Check for concurrent admin sessions
    final activeSessions = await sessionService.getActiveSessions(user.id);
    if (activeSessions.length > 1) {
      final allowMultiple = await configService.allowMultipleAdminSessions();
      if (!allowMultiple) {
        resolver.redirect('/session-conflict');
        return;
      }
    }

    // Verify session validity
    final sessionValid = await sessionService.validateAdminSession(user.id);
    if (!sessionValid) {
      resolver.redirect('/session-expired');
      return;
    }

    // Check session timeout
    final lastActivity = await sessionService.getLastActivity(user.id);
    const adminTimeout = Duration(minutes: 30);
    if (DateTime.now().difference(lastActivity) > adminTimeout) {
      await sessionService.expireSession(user.id);
      resolver.redirect('/session-timeout');
      return;
    }

    // Update session activity
    await sessionService.updateActivity(user.id);
    
    resolver.next();
  }
}

class AdminAuditGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user != null) {
      // Log all admin area access
      await auditService.logAccess(
        userId: user.id,
        action: 'admin_area_access',
        resource: state.uri.path,
        metadata: {
          'userAgent': await getUserAgent(context),
          'ipAddress': await getClientIP(context),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }

    resolver.next();
  }
}

// Financial Shell Security
@TypedShellRoute<FinancialShellRoute>(
  routes: [
    TypedGoRoute<FinancialDashboardRoute>(path: '/dashboard'),
    TypedGoRoute<FinancialReportsRoute>(path: '/reports'),
    TypedGoRoute<FinancialTransactionsRoute>(path: '/transactions'),
  ],
)
class FinancialShellRoute extends ShellRouteData with GuardedShellRoute {
  @override
  RouteGuard get guards => Guards.all([
    FinancialAccessGuard(),
    ComplianceGuard(),
    EncryptionGuard(),
  ]);

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget child) {
    return SecureFinancialLayout(child: child);
  }
}

class FinancialAccessGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }

    // Enhanced authentication for financial data
    if (!await mfaService.isVerified(user.id)) {
      resolver.redirect('/mfa-required');
      return;
    }

    // Financial access permissions
    if (!await permissionService.hasPermission(
      userId: user.id,
      resource: 'financial_data',
      action: 'access',
    )) {
      resolver.redirect('/unauthorized?area=financial');
      return;
    }

    // Geographic restrictions for financial access
    final userLocation = await locationService.getUserLocation();
    if (!await complianceService.isFinancialAccessAllowed(userLocation)) {
      resolver.redirect('/geo-restricted?area=financial');
      return;
    }

    // Business hours restriction for financial operations
    if (!await scheduleService.isFinancialAccessAllowed()) {
      resolver.redirect('/financial-hours-restricted');
      return;
    }

    resolver.next();
  }
}

class ComplianceGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.next();
      return;
    }

    // Check compliance training completion
    if (!await complianceService.hasCompletedTraining(user.id)) {
      resolver.redirect('/compliance-training-required');
      return;
    }

    // Verify regulatory compliance
    final userRegion = await locationService.getUserRegion();
    if (!await regulatoryService.isCompliant(userRegion)) {
      resolver.redirect('/regulatory-compliance-issue');
      return;
    }

    // Check for compliance violations
    if (await complianceService.hasViolations(user.id)) {
      resolver.redirect('/compliance-violations');
      return;
    }

    resolver.next();
  }
}
```

### Layer 3: Route-Level Security

```dart
// lib/security/route_security.dart

// High-security financial transaction route
@TypedGoRoute<CreateTransactionRoute>(path: '/financial/transaction/create')
class CreateTransactionRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    // Basic authentication (from shell)
    TransactionCreationGuard(),
    FraudDetectionGuard(),
    TransactionLimitGuard(),
    AMLComplianceGuard(),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CreateTransactionScreen();
  }
}

class TransactionCreationGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }

    // Transaction creation permissions
    if (!await permissionService.hasPermission(
      userId: user.id,
      resource: 'transaction',
      action: 'create',
    )) {
      resolver.redirect('/unauthorized?action=create_transaction');
      return;
    }

    // Account verification status
    if (!await accountService.isVerified(user.id)) {
      resolver.redirect('/verify-account');
      return;
    }

    // Daily transaction limit check
    final todayTransactions = await transactionService.getTodayTransactionCount(user.id);
    final dailyLimit = await limitService.getDailyTransactionLimit(user.id);
    
    if (todayTransactions >= dailyLimit) {
      resolver.redirect('/daily-limit-exceeded');
      return;
    }

    resolver.next();
  }
}

class FraudDetectionGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.next();
      return;
    }

    // Behavioral analysis
    final riskScore = await fraudService.calculateRiskScore(
      userId: user.id,
      context: {
        'ipAddress': await getClientIP(context),
        'userAgent': await getUserAgent(context),
        'timestamp': DateTime.now().toIso8601String(),
        'location': await locationService.getUserLocation(),
      },
    );

    if (riskScore > 0.8) {
      // High risk - additional verification required
      resolver.redirect('/additional-verification');
      return;
    } else if (riskScore > 0.5) {
      // Medium risk - enhanced monitoring
      await fraudService.enableEnhancedMonitoring(user.id);
    }

    // Check for suspicious patterns
    if (await fraudService.hasSuspiciousPatterns(user.id)) {
      resolver.redirect('/fraud-investigation');
      return;
    }

    resolver.next();
  }
}

class AMLComplianceGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.next();
      return;
    }

    // AML screening
    if (await amlService.isOnWatchlist(user.id)) {
      resolver.redirect('/aml-review-required');
      return;
    }

    // Transaction monitoring thresholds
    final monthlyVolume = await transactionService.getMonthlyVolume(user.id);
    const reportingThreshold = 10000.0;
    
    if (monthlyVolume > reportingThreshold) {
      if (!await amlService.hasReportingCompliance(user.id)) {
        resolver.redirect('/aml-reporting-required');
        return;
      }
    }

    // Source of funds verification
    if (!await amlService.hasVerifiedSourceOfFunds(user.id)) {
      resolver.redirect('/verify-source-of-funds');
      return;
    }

    resolver.next();
  }
}

// Sensitive user data route
@TypedGoRoute<UserDataExportRoute>(path: '/data/export')
class UserDataExportRoute extends GoRouteData with GuardedRoute {
  @override
  RouteGuard get guards => Guards.all([
    DataExportPermissionGuard(),
    DataProtectionGuard(),
    ExportLimitGuard(),
    PrivacyComplianceGuard(),
  ]);

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UserDataExportScreen();
  }
}

class DataProtectionGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.redirect('/login');
      return;
    }

    // Enhanced verification for data export
    if (!await mfaService.isRecentlyVerified(
      user.id,
      duration: const Duration(minutes: 10),
    )) {
      resolver.redirect('/reverify-mfa?action=data_export');
      return;
    }

    // Check for data export cooldown
    final lastExport = await dataService.getLastExportTime(user.id);
    const cooldownPeriod = Duration(hours: 24);
    
    if (lastExport != null && 
        DateTime.now().difference(lastExport) < cooldownPeriod) {
      resolver.redirect('/export-cooldown');
      return;
    }

    // Verify user identity with additional challenges
    if (!await identityService.isIdentityVerified(user.id)) {
      resolver.redirect('/additional-identity-verification');
      return;
    }

    resolver.next();
  }
}

class PrivacyComplianceGuard extends GoRouterGuard {
  @override
  FutureOr<void> onGoRouterNavigation(
    NavigationResolver resolver,
    BuildContext context,
    GoRouterState state,
  ) async {
    final user = getCurrentUser(context);
    
    if (user == null) {
      resolver.next();
      return;
    }

    // GDPR compliance checks
    final userRegion = await locationService.getUserRegion();
    if (await privacyService.requiresGDPRCompliance(userRegion)) {
      if (!await privacyService.hasGDPRConsent(user.id)) {
        resolver.redirect('/gdpr-consent-required');
        return;
      }
    }

    // CCPA compliance for California users
    if (await privacyService.requiresCCPACompliance(userRegion)) {
      if (!await privacyService.hasCCPADisclosure(user.id)) {
        resolver.redirect('/ccpa-disclosure-required');
        return;
      }
    }

    // Log data access for compliance
    await auditService.logDataAccess(
      userId: user.id,
      dataType: 'user_export',
      purpose: 'user_requested_export',
    );

    resolver.next();
  }
}
```

## Security Context Provider

```dart
// lib/security/security_context.dart
class SecurityContext {
  static final Map<String, SecurityLevel> _routeSecurityLevels = {
    '/': SecurityLevel.public,
    '/login': SecurityLevel.public,
    '/dashboard': SecurityLevel.authenticated,
    '/admin': SecurityLevel.admin,
    '/financial': SecurityLevel.highSecurity,
    '/data/export': SecurityLevel.critical,
  };

  static SecurityLevel getSecurityLevel(String path) {
    for (final entry in _routeSecurityLevels.entries) {
      if (path.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return SecurityLevel.authenticated;
  }

  static List<Type> getRequiredGuards(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.public:
        return [];
      case SecurityLevel.authenticated:
        return [AuthGuard];
      case SecurityLevel.admin:
        return [AuthGuard, AdminAccessGuard, MFAGuard];
      case SecurityLevel.highSecurity:
        return [AuthGuard, MFAGuard, EncryptionGuard, AuditGuard];
      case SecurityLevel.critical:
        return [
          AuthGuard,
          MFAGuard,
          EncryptionGuard,
          AuditGuard,
          DataProtectionGuard,
          ComplianceGuard,
        ];
    }
  }
}

enum SecurityLevel {
  public,
  authenticated,
  admin,
  highSecurity,
  critical,
}
```

## Router Configuration

```dart
// lib/router/app_router.dart
final appRouter = GoRouter(
  routes: [
    // Public routes
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    
    // Admin shell with multi-layer protection
    ...AdminShellRoute().routes,
    
    // Financial shell with enhanced security
    ...FinancialShellRoute().routes,
    
    // Individual protected routes
    ...UserDataExportRoute().routes,
  ],
  
  // Global router-level security
  redirect: RouterSecurity.createGlobalSecurityRedirect(),
  
  // Error handling
  errorBuilder: (context, state) => ErrorScreen(error: state.error),
  
  // Debug logging
  debugLogDiagnostics: kDebugMode,
);
```

## Security Monitoring

```dart
// lib/security/security_monitor.dart
class SecurityMonitor {
  static void initialize() {
    // Monitor guard execution times
    GuardExecutionMonitor.startMonitoring();
    
    // Track security violations
    SecurityViolationTracker.initialize();
    
    // Real-time threat detection
    ThreatDetectionService.startMonitoring();
  }

  static void logSecurityEvent({
    required String eventType,
    required String userId,
    required Map<String, dynamic> details,
  }) {
    final event = SecurityEvent(
      type: eventType,
      userId: userId,
      timestamp: DateTime.now(),
      details: details,
    );

    // Log to security audit system
    auditService.logSecurityEvent(event);

    // Check for threat patterns
    threatDetectionService.analyzeEvent(event);

    // Real-time alerts for critical events
    if (_isCriticalEvent(eventType)) {
      alertService.sendCriticalAlert(event);
    }
  }

  static bool _isCriticalEvent(String eventType) {
    const criticalEvents = [
      'unauthorized_admin_access',
      'failed_mfa_verification',
      'suspicious_financial_activity',
      'data_export_violation',
      'fraud_detection_trigger',
    ];
    return criticalEvents.contains(eventType);
  }
}
```

## Testing Multi-Layer Security

```dart
void main() {
  group('Multi-Layer Security', () {
    testWidgets('layers work together correctly', (tester) async {
      // Test that all security layers are enforced
      await tester.pumpWidget(
        TestApp(router: appRouter),
      );

      // Try to access admin route without authentication
      AdminDashboardRoute().go(tester.element(find.byType(TestApp)));
      await tester.pumpAndSettle();

      // Should be redirected to login (router level)
      expect(find.text('Login'), findsOneWidget);

      // Login but without admin role
      await authenticateUser(tester, regularUser);
      AdminDashboardRoute().go(tester.element(find.byType(TestApp)));
      await tester.pumpAndSettle();

      // Should be blocked by admin shell guard
      expect(find.text('Unauthorized'), findsOneWidget);

      // Login as admin but without MFA
      await authenticateUser(tester, adminUserWithoutMFA);
      AdminDashboardRoute().go(tester.element(find.byType(TestApp)));
      await tester.pumpAndSettle();

      // Should be redirected to MFA verification
      expect(find.text('MFA Verification'), findsOneWidget);
    });

    test('security context provides correct levels', () {
      expect(
        SecurityContext.getSecurityLevel('/admin/users'),
        SecurityLevel.admin,
      );
      
      expect(
        SecurityContext.getSecurityLevel('/financial/transactions'),
        SecurityLevel.highSecurity,
      );
      
      expect(
        SecurityContext.getSecurityLevel('/data/export'),
        SecurityLevel.critical,
      );
    });
  });
}
```

This multi-layer protection system provides comprehensive security through defense in depth, ensuring that even if one layer fails, others continue to protect your application and user data.

## Key Security Principles Demonstrated

1. **Defense in Depth**: Multiple security layers protect against various threats
2. **Principle of Least Privilege**: Users get minimal necessary access
3. **Zero Trust**: Every request is verified regardless of source
4. **Fail Secure**: Security failures result in access denial
5. **Audit Everything**: All security-relevant actions are logged
6. **Risk-Based Security**: Security measures scale with risk level
7. **Compliance by Design**: Regulatory requirements built into guards
8. **Real-Time Monitoring**: Continuous threat detection and response

## Next Steps

- 📋 Review [Best Practices](/guides/best-practices/)
- 🧪 Learn [Testing Strategies](/guides/testing-guards/)
- ⚡ Explore [Performance Optimization](/guides/performance/)
- 🔒 Study [Security Patterns](/guides/security-patterns/)
