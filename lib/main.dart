import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'widgets/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape for tablet POS
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status / navigation bars for full-screen POS experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const ProviderScope(
      child: OrderlyyApp(),
    ),
  );
}

class OrderlyyApp extends ConsumerWidget {
  const OrderlyyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      // Design canvas matches a 10-inch tablet in landscape
      designSize: const Size(
        AppConstants.designWidth,
        AppConstants.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return InactivityScope(
          child: MaterialApp.router(
            title: 'Orderlyy POS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            themeMode: ThemeMode.light,
            routerConfig: router,
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              // Clamp text scaling: prevents Windows 125%/150% DPI from
              // breaking POS layouts while still supporting mild accessibility scaling.
              final clampedTextScaler = mediaQueryData.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.10,
              );
              return MediaQuery(
                data: mediaQueryData.copyWith(textScaler: clampedTextScaler),
                child: child!,
              );
            },
          ),
        );
      },
    );
  }
}
