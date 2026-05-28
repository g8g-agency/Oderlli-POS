/// Helper utility to determine time-of-day greeting messages.
abstract final class GreetingHelper {
  /// Returns a contextual greeting message with matching emoji based on the [time].
  static String getGreetingMessage([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning ☀️';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon 🌤';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening 🌆';
    } else {
      return 'Good Night 🌙';
    }
  }
}
