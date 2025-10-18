<?php

namespace App\Exceptions;

use App\Enums\ErrorCodesEnum;
use App\Helpers\ApiResponder;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Exceptions\InvalidSignatureException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

final class ApiExceptionMapper
{
  public static function mapToApiResponse(\Throwable $e): JsonResponse
  {
    if ($e instanceof CustomException) {
      if ($e->statusCode === 500) {
        \Log::critical($e->exception);
      }

      return ApiResponder::sendApiResponse(
        responseDto: $e->toApiResponseDto(),
        statusCode: $e->statusCode,
      );
    }

    if ($e instanceof ValidationException) {
      return ApiResponder::validationError(errors: $e->errors());
    }

    if ($e instanceof AuthenticationException) {
      return ApiResponder::unauthorized();
    }

    if ($e instanceof InvalidSignatureException) {
      return ApiResponder::invalidSignature();
    }

    if ($e instanceof AccessDeniedHttpException) {
      return ApiResponder::forbidden();
    }

    if ($e instanceof NotFoundHttpException) {
      return ApiResponder::notFound();
    }

    if ($e instanceof MethodNotAllowedHttpException) {
      return ApiResponder::methodNotAllowed();
    }

    return self::unexpectedError($e);
  }

  private static function unexpectedError(\Throwable $e): JsonResponse
  {
    \Log::critical($e);

    if (config('app.debug')) {
      return ApiResponder::serverError(
        message: $e->getMessage() . ' en ' . $e->getFile() . ' línea ' . $e->getLine(),
        errorCode: ErrorCodesEnum::UNHANDLED_EXCEPTION,
        errors: ['trace' => $e->getTrace()]
      );
    }

    return ApiResponder::serverError();
  }
}
