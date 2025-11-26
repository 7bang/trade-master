import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'services/supabase_service.dart';
import 'widgets/main_navigation_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/business_setup_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/customer/customer_detail_screen.dart';
import 'screens/customer/customer_form_screen.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/product_form_screen.dart';
import 'screens/transaction/transaction_list_screen.dart';
import 'screens/transaction/transaction_form_screen.dart';
import 'screens/transaction/transaction_detail_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  // Flutter 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 앱 실행
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '거래의장인',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // 강제로 라이트 모드 사용
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  // 라우터 생성
  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        final supabase = SupabaseService();
        final user = supabase.currentUser;
        final isAuthRoute = state.matchedLocation == '/' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/business-setup';

        // 로그인되지 않은 경우
        if (user == null) {
          if (isAuthRoute) return null;
          return '/';
        }

        // 로그인된 경우 - 비즈니스 정보 확인
        try {
          await supabase.getBusiness(user.id);

          // 비즈니스가 있는 경우
          if (isAuthRoute) {
            return '/customers';
          }
          return null;
        } catch (e) {
          // 에러 발생 시 (비즈니스가 없는 경우) business-setup으로
          if (state.matchedLocation != '/business-setup') {
            return '/business-setup';
          }
          return null;
        }
      },
      refreshListenable: GoRouterRefreshStream(
        Supabase.instance.client.auth.onAuthStateChange,
      ),
      routes: [
        // ========== 인증 관련 ==========
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/business-setup',
          builder: (context, state) => const BusinessSetupScreen(),
        ),

        // ========== 하단 네비게이션이 있는 메인 화면 ==========
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainNavigationShell(navigationShell: navigationShell);
          },
          branches: [
            // 거래처 탭
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/customers',
                  builder: (context, state) => const CustomerListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const CustomerFormScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return CustomerDetailScreen(customerId: id);
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) {
                            final id = state.pathParameters['id']!;
                            return CustomerFormScreen(customerId: id);
                          },
                        ),
                        GoRoute(
                          path: 'transactions/new',
                          builder: (context, state) {
                            final customerId = state.pathParameters['id']!;
                            return TransactionFormScreen(customerId: customerId);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // 품목 탭
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/products',
                  builder: (context, state) => const ProductListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const ProductFormScreen(),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return ProductFormScreen(productId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // 거래내역 탭
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/transactions',
                  builder: (context, state) => const TransactionListScreen(),
                ),
              ],
            ),

            // 설정 탭
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),

        // ========== 거래 관련 (모달 형식) ==========
        GoRoute(
          path: '/transactions/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TransactionDetailScreen(transactionId: id);
          },
        ),
        GoRoute(
          path: '/transactions/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final customerId = state.uri.queryParameters['customerId'];
            return TransactionFormScreen(
              customerId: customerId!,
              transactionId: id,
            );
          },
        ),
      ],
    );
  }
}

// Stream을 Listenable로 변환하는 헬퍼 클래스
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (AuthState _) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
