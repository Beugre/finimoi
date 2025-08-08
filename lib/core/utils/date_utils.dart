import 'package:intl/intl.dart';

class DateUtils {
  static const String defaultDateFormat = 'dd/MM/yyyy';
  static const String defaultTimeFormat = 'HH:mm';
  static const String defaultDateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss.SSSZ';

  /// Format date with default format
  static String formatDate(DateTime date, {String? format}) {
    final formatter = DateFormat(format ?? defaultDateFormat, 'fr_FR');
    return formatter.format(date);
  }

  /// Format time with default format
  static String formatTime(DateTime time, {String? format}) {
    final formatter = DateFormat(format ?? defaultTimeFormat, 'fr_FR');
    return formatter.format(time);
  }

  /// Format datetime with default format
  static String formatDateTime(DateTime dateTime, {String? format}) {
    final formatter = DateFormat(format ?? defaultDateTimeFormat, 'fr_FR');
    return formatter.format(dateTime);
  }

  /// Format date for API
  static String formatDateForApi(DateTime date) {
    final formatter = DateFormat(apiDateFormat);
    return formatter.format(date);
  }

  /// Format datetime for API
  static String formatDateTimeForApi(DateTime dateTime) {
    final formatter = DateFormat(apiDateTimeFormat);
    return formatter.format(dateTime);
  }

  /// Parse date from string
  static DateTime? parseDate(String dateString, {String? format}) {
    try {
      final formatter = DateFormat(format ?? defaultDateFormat, 'fr_FR');
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse datetime from string
  static DateTime? parseDateTime(String dateTimeString, {String? format}) {
    try {
      final formatter = DateFormat(format ?? defaultDateTimeFormat, 'fr_FR');
      return formatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Parse date from API format
  static DateTime? parseDateFromApi(String dateString) {
    try {
      final formatter = DateFormat(apiDateFormat);
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse datetime from API format
  static DateTime? parseDateTimeFromApi(String dateTimeString) {
    try {
      final formatter = DateFormat(apiDateTimeFormat);
      return formatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Get relative time (e.g., "il y a 2 heures")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }

  /// Get time ago (e.g., "2h", "3j")
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}a';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is this year
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(
      date.year,
      date.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));
  }

  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Get number of days in month
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get age from birth date
  static int getAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Check if date is valid
  static bool isValidDate(String dateString, {String? format}) {
    return parseDate(dateString, format: format) != null;
  }

  /// Get business days between two dates
  static int getBusinessDays(DateTime startDate, DateTime endDate) {
    int businessDays = 0;
    DateTime current = startDate;

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (current.weekday < 6) {
        // Monday = 1, Saturday = 6
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return businessDays;
  }

  /// Add business days to date
  static DateTime addBusinessDays(DateTime date, int businessDays) {
    DateTime result = date;
    int addedDays = 0;

    while (addedDays < businessDays) {
      result = result.add(const Duration(days: 1));
      if (result.weekday < 6) {
        // Skip weekends
        addedDays++;
      }
    }

    return result;
  }

  /// Get month name in French
  static String getMonthName(int month) {
    const monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return monthNames[month - 1];
  }

  /// Get day name in French
  static String getDayName(int weekday) {
    const dayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return dayNames[weekday - 1];
  }
}
