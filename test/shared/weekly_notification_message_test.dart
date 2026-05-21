import 'package:flutter_test/flutter_test.dart';
import 'package:pregnova/shared/weekly_notification_message.dart';

void main() {
  group('WeeklyNotificationMessage', () {
    test('returns first trimester message for weeks 1 through 13', () {
      expect(
        WeeklyNotificationMessage.messageFor(week: 1, languageCode: 'tr'),
        contains('1. trimester'),
      );
      expect(
        WeeklyNotificationMessage.messageFor(week: 13, languageCode: 'tr'),
        contains('1. trimester'),
      );
    });

    test('returns second trimester message for weeks 14 through 27', () {
      expect(
        WeeklyNotificationMessage.messageFor(week: 14, languageCode: 'tr'),
        contains('2. trimester'),
      );
      expect(
        WeeklyNotificationMessage.messageFor(week: 27, languageCode: 'tr'),
        contains('2. trimester'),
      );
    });

    test('returns third trimester message for weeks 28 through 42', () {
      expect(
        WeeklyNotificationMessage.messageFor(week: 28, languageCode: 'tr'),
        contains('3. trimester'),
      );
      expect(
        WeeklyNotificationMessage.messageFor(week: 42, languageCode: 'tr'),
        contains('3. trimester'),
      );
    });

    test('clamps out-of-range weeks to pregnancy bounds', () {
      expect(
        WeeklyNotificationMessage.messageFor(week: 0, languageCode: 'tr'),
        contains('1. trimester'),
      );
      expect(
        WeeklyNotificationMessage.messageFor(week: 99, languageCode: 'tr'),
        contains('3. trimester'),
      );
    });

    test('returns English text for English locale variants', () {
      expect(
        WeeklyNotificationMessage.messageFor(week: 8, languageCode: 'en'),
        contains('First trimester'),
      );
      expect(
        WeeklyNotificationMessage.messageFor(week: 20, languageCode: 'en-US'),
        contains('Second trimester'),
      );
      expect(
        WeeklyNotificationMessage.messageFor(week: 32, languageCode: 'en_GB'),
        contains('Third trimester'),
      );
    });
  });
}
