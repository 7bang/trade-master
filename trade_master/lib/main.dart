import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/providers.dart';
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
import 'screens/transaction/multi_transaction_form_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/business_edit_screen.dart';

void main() async {
  // Flutter 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드 (.env)
  await dotenv.load();

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
      title: '폰거래장 온',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      // 한글 지원
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
    );
  }

  // 라우터 생성
  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        final user = ref.read(supabaseServiceProvider).currentUser;
        final location = state.matchedLocation;
        final isLoginRoute = location == '/' || location == '/signup';
        final isSetupRoute = location == '/business-setup';

        // 로그인되지 않은 경우
        if (user == null) {
          return (isLoginRoute || isSetupRoute) ? null : '/';
        }

        // 로그인된 경우 - 사업장 확인 (캐시 사용: 화면 이동마다 서버를 부르지 않음)
        try {
          final business =
              await ref.read(businessByUserProvider(user.id).future);
          if (business == null) {
            return isSetupRoute ? null : '/business-setup';
          }
          return (isLoginRoute || isSetupRoute) ? '/customers' : null;
        } catch (_) {
          // 네트워크 등 조회 실패 — 사업장이 없다고 단정하지 않는다.
          // 목록 화면이 오류와 "다시 시도"를 보여주고, 다음 이동 때 다시 조회한다.
          ref.invalidate(businessByUserProvider(user.id));
          return isLoginRoute ? '/customers' : null;
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
                        GoRoute(
                          path: 'transactions/multi',
                          builder: (context, state) {
                            final customerId = state.pathParameters['id']!;
                            return MultiTransactionFormScreen(customerId: customerId);
                          },
                        ),
                        GoRoute(
                          path: 'transactions/:transactionId/edit',
                          builder: (context, state) {
                            final customerId = state.pathParameters['id']!;
                            final transactionId = state.pathParameters['transactionId']!;
                            return TransactionFormScreen(
                              customerId: customerId,
                              transactionId: transactionId,
                            );
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
                  routes: [
                    GoRoute(
                      path: 'business/edit',
                      builder: (context, state) => const BusinessEditScreen(),
                    ),
                  ],
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
