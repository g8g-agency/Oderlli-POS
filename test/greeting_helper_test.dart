import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_pos/core/utils/greeting_helper.dart';

void main() {
  group('GreetingHelper tests', () {
    test('Good Morning range (5:00 AM to 11:59 AM)', () {
      // 5:00 AM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 5, 0)),
        'Good Morning ☀️',
      );
      // 6:36 AM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 6, 36)),
        'Good Morning ☀️',
      );
      // 11:59 AM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 11, 59)),
        'Good Morning ☀️',
      );
    });

    test('Good Afternoon range (12:00 PM to 4:59 PM)', () {
      // 12:00 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 12, 0)),
        'Good Afternoon 🌤',
      );
      // 1:30 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 13, 30)),
        'Good Afternoon 🌤',
      );
      // 4:59 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 16, 59)),
        'Good Afternoon 🌤',
      );
    });

    test('Good Evening range (5:00 PM to 8:59 PM)', () {
      // 5:00 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 17, 0)),
        'Good Evening 🌆',
      );
      // 7:15 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 19, 15)),
        'Good Evening 🌆',
      );
      // 8:59 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 20, 59)),
        'Good Evening 🌆',
      );
    });

    test('Good Night range (9:00 PM to 4:59 AM)', () {
      // 9:00 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 21, 0)),
        'Good Night 🌙',
      );
      // 11:59 PM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 23, 59)),
        'Good Night 🌙',
      );
      // 12:00 AM (Midnight)
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 0, 0)),
        'Good Night 🌙',
      );
      // 3:00 AM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 3, 0)),
        'Good Night 🌙',
      );
      // 4:59 AM
      expect(
        GreetingHelper.getGreetingMessage(DateTime(2026, 5, 28, 4, 59)),
        'Good Night 🌙',
      );
    });

    test('Uses local device time by default', () {
      final currentHour = DateTime.now().hour;
      final greeting = GreetingHelper.getGreetingMessage();
      if (currentHour >= 5 && currentHour < 12) {
        expect(greeting, 'Good Morning ☀️');
      } else if (currentHour >= 12 && currentHour < 17) {
        expect(greeting, 'Good Afternoon 🌤');
      } else if (currentHour >= 17 && currentHour < 21) {
        expect(greeting, 'Good Evening 🌆');
      } else {
        expect(greeting, 'Good Night 🌙');
      }
    });
  });
}
