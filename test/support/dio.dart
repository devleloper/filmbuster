import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

Response<dynamic> okResponse(Object? data) =>
    Response(requestOptions: RequestOptions(), statusCode: 200, data: data);

/// A failed request; [statusCode] adds a response with [data].
DioException dioError({
  DioExceptionType type = DioExceptionType.badResponse,
  int? statusCode,
  Object? data,
}) => DioException(
  requestOptions: RequestOptions(),
  type: type,
  response: statusCode == null
      ? null
      : Response(
          requestOptions: RequestOptions(),
          statusCode: statusCode,
          data: data,
        ),
);

extension StubbedGet on MockDio {
  void answerGet(Object? data) => when(
    () => get<dynamic>(any(), queryParameters: any(named: 'queryParameters')),
  ).thenAnswer((_) async => okResponse(data));

  void failGet(DioException error) => when(
    () => get<dynamic>(any(), queryParameters: any(named: 'queryParameters')),
  ).thenThrow(error);
}
