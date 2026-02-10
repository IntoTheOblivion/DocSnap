import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
  }
  
  static String formatForFilename(DateTime date) {
    return DateFormat('yyyyMMdd_HHmmss').format(date);
  }
}
