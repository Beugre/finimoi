abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({required this.message, this.code, this.details});

  @override
  String toString() => 'Failure: $message';
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code, super.details});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, super.details});
}

class ConnectionFailure extends Failure {
  const ConnectionFailure({required super.message, super.code, super.details});
}

// Authentication Failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.details});
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class InvalidAmountFailure extends Failure {
  const InvalidAmountFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Firebase Failures
class FirebaseFailure extends Failure {
  const FirebaseFailure({required super.message, super.code, super.details});
}

class FirestoreFailure extends Failure {
  const FirestoreFailure({required super.message, super.code, super.details});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code, super.details});
}

// Payment Failures
class PaymentFailure extends Failure {
  const PaymentFailure({required super.message, super.code, super.details});
}

class TransactionFailure extends Failure {
  const TransactionFailure({required super.message, super.code, super.details});
}

class CardFailure extends Failure {
  const CardFailure({required super.message, super.code, super.details});
}

// Biometric Failures
class BiometricFailure extends Failure {
  const BiometricFailure({required super.message, super.code, super.details});
}

class BiometricNotAvailableFailure extends Failure {
  const BiometricNotAvailableFailure({
    required super.message,
    super.code,
    super.details,
  });
}

class BiometricNotEnrolledFailure extends Failure {
  const BiometricNotEnrolledFailure({
    required super.message,
    super.code,
    super.details,
  });
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.details});
}

// Location Failures
class LocationFailure extends Failure {
  const LocationFailure({required super.message, super.code, super.details});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code, super.details});
}

// General Failures
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.code, super.details});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code, super.details});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message, super.code, super.details});
}

class UnsupportedOperationFailure extends Failure {
  const UnsupportedOperationFailure({
    required super.message,
    super.code,
    super.details,
  });
}
