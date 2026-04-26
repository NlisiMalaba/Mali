sealed class Failure {
  const Failure({
    required this.message,
    this.cause,
  });

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType(message: $message, cause: $cause)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other.runtimeType == runtimeType &&
        other is Failure &&
        other.message == message &&
        other.cause == cause;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, cause);
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.cause,
    this.statusCode,
  });

  final int? statusCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkFailure &&
        other.message == message &&
        other.cause == cause &&
        other.statusCode == statusCode;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, cause, statusCode);
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.cause,
    this.field,
  });

  final String? field;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationFailure &&
        other.message == message &&
        other.cause == cause &&
        other.field == field;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, cause, field);
}

final class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.cause,
  });
}

final class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.cause,
  });
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.cause,
    this.resource,
  });

  final String? resource;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotFoundFailure &&
        other.message == message &&
        other.cause == cause &&
        other.resource == resource;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, cause, resource);
}
