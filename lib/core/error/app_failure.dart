/// A failure the UI can show; [message] is user-facing copy.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({String? message, super.cause, super.stackTrace})
    : super(
        message ??
            'Cannot connect to the server. Please check your connection.',
      );
}

class TimeoutFailure extends AppFailure {
  const TimeoutFailure({String? message, super.cause, super.stackTrace})
    : super(
        message ?? 'Connection timeout. Please check your network and retry.',
      );
}

/// The server answered with a 5xx or 429 status.
class ServerFailure extends AppFailure {
  const ServerFailure({String? message, super.cause, super.stackTrace})
    : super(message ?? 'Server error. Please try again later.');
}

/// A 404, or nothing usable in the answer.
class NotFoundFailure extends AppFailure {
  const NotFoundFailure({String? message, super.cause, super.stackTrace})
    : super(message ?? 'Not found.');

  static const movieMessage = 'Movie not found.';
  static const personMessage = 'Person not found.';
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({String? message, super.cause, super.stackTrace})
    : super(message ?? 'Invalid request. Please check the entered data.');
}

class ParsingFailure extends AppFailure {
  const ParsingFailure({String? message, super.cause, super.stackTrace})
    : super(message ?? 'Unexpected response from the server.');
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({String? message, super.cause, super.stackTrace})
    : super(message ?? 'Something went wrong. Please try again.');
}

extension ToAppFailure on Object {
  AppFailure toAppFailure([StackTrace? stackTrace]) => switch (this) {
    final AppFailure failure => failure,
    final error => UnknownFailure(cause: error, stackTrace: stackTrace),
  };
}
