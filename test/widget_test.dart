import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orderlli_pos/main.dart';
import 'package:orderlli_pos/core/constants/app_constants.dart';

void main() {
  testWidgets('Orderlli POS app smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(
          AppConstants.designWidth,
          AppConstants.designHeight,
        ),
        builder: (_, _) => const ProviderScope(child: OrderlliApp()),
      ),
    );
    // Splash screen should render immediately
    await tester.pump();
    expect(find.byType(OrderlliApp), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
