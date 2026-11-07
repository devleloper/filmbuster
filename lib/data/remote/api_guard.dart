import 'package:dio/dio.dart';

import '../../core/error/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/failure_mapper.dart';

const _log = AppLogger('Api');

/// Converts whatever [call] throws into an [AppFailure]; a response of the
/// wrong shape becomes a [ParsingFailure]. See [FailureMapper.fromDio] for
/// [statusMessages] and [fallbackMessage].
Future<T> guardApiCall<T>(
  Future<T> Function() call, {
  Map<int, String> statusMessages = const {},
  String? fallbackMessage,
}) async {
  try {
    return await call();
  } on DioException catch (error) {
    throw FailureMapper.fromDio(
      error,
      statusMessages: statusMessages,
      fallbackMessage: fallbackMessage,
    );
  } catch (error, stackTrace) {
    if (error is FormatException || error is TypeError) {
      // A FormatException's source is the rejected input, such as a signed
      // URL, so only its message is logged.
      final reason = error is FormatException ? error.message : error;
      _log.error('response does not match the contract', reason, stackTrace);
      throw ParsingFailure(cause: error, stackTrace: stackTrace);
    }
    throw UnknownFailure(cause: error, stackTrace: stackTrace);
  }
}
