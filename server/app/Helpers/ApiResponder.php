<?php

namespace App\Helpers;

use App\DTOs\ApiResponseDto;
use App\DTOs\CursorPaginationDto;
use App\DTOs\ErrorDto;
use App\DTOs\PaginationDto;
use App\Enums\ErrorCodesEnum;
use App\Enums\ResponseStatusEnum;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use Illuminate\Pagination\LengthAwarePaginator;

final class ApiResponder
{
  public static function sendApiResponse(
    ApiResponseDto $responseDto,
    int $statusCode = Response::HTTP_OK,
  ): JsonResponse {
    return response()->json($responseDto->toArray(), $statusCode);
  }

  /**
   * Respuesta de éxito (200 OK).
   */
  public static function success(
    string $message = 'Operación completada exitosamente.',
    mixed $data = null,
    ?LengthAwarePaginator $pagination = null,
    ?CursorPaginationDto $cursorPagination = null,
    array $metadata = []
  ): JsonResponse {
    $paginationDto = $pagination !== null
      ? PaginationDto::fromLengthAwarePaginator($pagination)
      : null;

    if ($data === null && $paginationDto !== null) {
      $data = $paginationDto->items;
    }

    $responseDto = new ApiResponseDto(
      status: ResponseStatusEnum::SUCCESS,
      message: $message,
      data: $data,
      pagination: $paginationDto,
      cursorPagination: $cursorPagination,
      metadata: $metadata,
    );

    return self::sendApiResponse($responseDto, Response::HTTP_OK);
  }

  /**
   * Respuesta de "Creado" (201 Created).
   */
  public static function created(
    string $message = 'Recurso creado exitosamente.',
    mixed $data = null
  ): JsonResponse {
    $responseDto = new ApiResponseDto(
      status: ResponseStatusEnum::SUCCESS,
      message: $message,
      data: $data,
    );

    return self::sendApiResponse($responseDto, Response::HTTP_CREATED);
  }

  /**
   * Respuesta de "Aceptado" (202 Accepted).
   */
  public static function accepted(
    string $message = 'Petición aceptada para procesamiento.',
    mixed $data = null
  ): JsonResponse {
    $responseDto = new ApiResponseDto(
      status: ResponseStatusEnum::SUCCESS,
      message: $message,
      data: $data,
    );

    return self::sendApiResponse($responseDto, Response::HTTP_ACCEPTED);
  }

  /**
   * Respuesta de "Sin contenido" (204 No Content).
   */
  public static function noContent(
    string $message = 'Operación completada sin contenido de respuesta.'
  ): JsonResponse {
    $responseDto = new ApiResponseDto(
      status: ResponseStatusEnum::SUCCESS,
      message: $message,
    );

    return self::sendApiResponse($responseDto, Response::HTTP_NO_CONTENT);
  }

  /**
   * Respuesta de error del cliente (4xx).
   */
  public static function clientError(
    string $message = 'Error en la petición.',
    ?ErrorCodesEnum $errorCode = null,
    ?array $errors = null,
    int $statusCode = Response::HTTP_BAD_REQUEST
  ): JsonResponse {
    $errorDto = new ErrorDto(
      code: $errorCode ?? ErrorCodesEnum::CLIENT_ERROR,
      errors: $errors,
    );

    $responseDto = new ApiResponseDto(
      status: ResponseStatusEnum::FAIL,
      message: $message,
      error: $errorDto,
    );

    return self::sendApiResponse($responseDto, $statusCode);
  }

  /**
   * Respuesta de error del servidor (5xx).
   */
  public static function serverError(
    string $message = 'Error interno del servidor.',
    ?ErrorCodesEnum $errorCode = null,
    ?array $errors = null,
    int $statusCode = Response::HTTP_INTERNAL_SERVER_ERROR
  ): JsonResponse {
    $errorDto = new ErrorDto(
      code: $errorCode ?? ErrorCodesEnum::SERVER_ERROR,
      errors: $errors,
    );

    $responseDto = new ApiResponseDto(
      status: ResponseStatusEnum::ERROR,
      message: $message,
      error: $errorDto,
    );

    return self::sendApiResponse($responseDto, $statusCode);
  }

  public static function badRequest(
    string $message = 'La solicitud no pudo ser procesada debido a una sintaxis inválida o datos incorrectos.',
    ?array $errors = null
  ): JsonResponse {
    return self::clientError($message, ErrorCodesEnum::BAD_REQUEST, $errors, Response::HTTP_BAD_REQUEST);
  }

  public static function methodNotAllowed(
    string $message = 'Método HTTP no permitido para esta ruta.',
    ?array $errors = null
  ): JsonResponse {
    return self::clientError($message, ErrorCodesEnum::METHOD_NOT_ALLOWED, $errors, Response::HTTP_METHOD_NOT_ALLOWED);
  }

  public static function unauthorized(
    string $message = 'No autenticado. Por favor, inicie sesión.',
    ?array $errors = null
  ): JsonResponse {
    return self::clientError($message, ErrorCodesEnum::UNAUTHORIZED, $errors, Response::HTTP_UNAUTHORIZED);
  }

  public static function forbidden(
    string $message = 'No tiene permiso para realizar esta acción.',
    ?array $errors = null
  ): JsonResponse {
    return self::clientError($message, ErrorCodesEnum::FORBIDDEN, $errors, Response::HTTP_FORBIDDEN);
  }

  public static function invalidSignature(
    string $message = 'El enlace de descarga es inválido o ha expirado. Por favor, solicite uno nuevo.',
    ?array $errors = null
  ): JsonResponse {
    return self::clientError($message, ErrorCodesEnum::INVALID_SIGNED_URL, $errors, Response::HTTP_FORBIDDEN);
  }

  public static function notFound(
    string $message = 'El recurso solicitado no fue encontrado.',
    ?array $errors = null
  ): JsonResponse {
    return self::clientError($message, ErrorCodesEnum::NOT_FOUND, $errors, Response::HTTP_NOT_FOUND);
  }

  public static function validationError(
    string $message = 'Los datos proporcionados no son válidos.',
    array $errors = []
  ): JsonResponse {
    return self::clientError($message, ErrorCodesEnum::VALIDATION_ERROR, $errors, Response::HTTP_UNPROCESSABLE_ENTITY);
  }
}
