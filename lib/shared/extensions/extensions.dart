extension StringExtensions on String {
  /// Check if string is empty or null
  bool get isEmptyOrNull => isEmpty;

  /// Check if string is not empty and not null
  bool get isNotEmptyAndNotNull => isNotEmpty;

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Remove spaces
  String get removeSpaces => replaceAll(' ', '');

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is a valid phone number (simple check)
  bool get isValidPhoneNumber {
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(removeSpaces);
  }

  /// Check if string is numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Convert to double
  double? get toDouble {
    return double.tryParse(this);
  }

  /// Convert to int
  int? get toInt {
    return int.tryParse(this);
  }

  /// Mask email (e.g., j***@example.com)
  String get maskedEmail {
    if (!isValidEmail) return this;

    final parts = split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return this;

    final maskedUsername =
        '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    return '$maskedUsername@$domain';
  }

  /// Mask phone number (e.g., +225 07 ** ** 45)
  String get maskedPhoneNumber {
    if (length < 8) return this;

    final cleanNumber = removeSpaces.replaceAll('+', '');
    if (cleanNumber.length < 8) return this;

    final firstPart = cleanNumber.substring(0, 4);
    final lastPart = cleanNumber.substring(cleanNumber.length - 2);
    final middlePart = '*' * (cleanNumber.length - 6);

    return '+$firstPart$middlePart$lastPart';
  }

  /// Format as phone number
  String get formatPhoneNumber {
    final clean = removeSpaces.replaceAll('+', '');

    if (clean.length == 10 && clean.startsWith('0')) {
      // French format: 07 00 00 00 00
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} ${clean.substring(6, 8)} ${clean.substring(8, 10)}';
    } else if (clean.length == 8) {
      // Ivorian format: 07 00 00 00
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} ${clean.substring(6, 8)}';
    }

    return this;
  }

  /// Generate initials (max 2 characters)
  String get initials {
    if (isEmpty) return '';

    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Check if string contains only letters
  bool get isAlpha {
    return RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(this);
  }

  /// Check if string contains only alphanumeric characters
  bool get isAlphaNumeric {
    return RegExp(r'^[a-zA-Z0-9À-ÿ\s]+$').hasMatch(this);
  }

  /// Remove diacritics (accents)
  String get removeDiacritics {
    const withDiacritics =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDiacritics =
        'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

    String result = this;
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }

  /// Convert to kebab case
  String get toKebabCase {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Convert to snake case
  String get toSnakeCase {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Convert to camel case
  String get toCamelCase {
    final words = toLowerCase().split(RegExp(r'[^a-z0-9]+'));
    if (words.isEmpty) return '';

    final first = words.first;
    final rest = words.skip(1).map((word) => word.capitalize);

    return first + rest.join('');
  }

  /// Count words
  int get wordCount {
    return trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// Reverse string
  String get reverse {
    return split('').reversed.join('');
  }
}

extension NullableStringExtensions on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullAndNotEmpty => this != null && this!.isNotEmpty;

  /// Get value or default
  String orDefault(String defaultValue) => this ?? defaultValue;

  /// Get value or empty string
  String get orEmpty => this ?? '';
}

extension NumExtensions on num {
  /// Format as currency
  String get toCurrency {
    // This will be implemented with proper currency formatting
    return '${toStringAsFixed(0)} CFA';
  }

  /// Check if number is positive
  bool get isPositive => this > 0;

  /// Check if number is negative
  bool get isNegative => this < 0;

  /// Check if number is zero
  bool get isZero => this == 0;

  /// Get absolute value
  num get abs => this < 0 ? -this : this;

  /// Round to specific decimal places
  double toDecimalPlaces(int places) {
    final factor = 10.0 * places;
    return (this * factor).round() / factor;
  }
}

extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'à l\'instant';
    }
  }
}

extension ListExtensions<T> on List<T> {
  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if list is not null and not empty
  bool get isNotNullAndNotEmpty => isNotEmpty;

  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Add element if condition is true
  List<T> addIf(bool condition, T element) {
    if (condition) add(element);
    return this;
  }

  /// Add all elements if condition is true
  List<T> addAllIf(bool condition, Iterable<T> elements) {
    if (condition) addAll(elements);
    return this;
  }

  /// Remove duplicates
  List<T> get unique => toSet().toList();

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size < length) ? i + size : length));
    }
    return chunks;
  }
}
