<?php

namespace App\Exceptions;

use App\DTOs\ApiResponseDto;
use App\DTOs\ErrorDto;
use App\Enums\ErrorCodesEnum;
use App\Enums\ResponseStatusEnum;
use Exception;
use Illuminate\Http\Response;

class CustomException extends Exception
{
  public readonly int $statusCode;
  public readonly ResponseStatusEnum $status;
  public readonly ?ErrorCodesEnum $errorCode;
  public readonly ?array $errors;
  public readonly ?\Throwable $exception;

  public function __construct(
    int $statusCode,
    string $message,
    ResponseStatusEnum $status,
    ?ErrorCodesEnum $errorCode = null,
    ?array $errors = null,
    ?\Throwable $exception = null,
  ) {
    parent::__construct($message, 0, null);
    $this->statusCode = $statusCode;
    $this->status = $status;
    $this->errorCode = $errorCode;
    $this->errors = $errors;
    $this->exception = $exception;
  }

  public function toApiResponseDto(): ApiResponseDto
  {
    $errorDto = null;
    if ($this->errorCode !== null || !empty($this->errors)) {
      $errorDto = new ErrorDto(
        code: $this->errorCode ?? ErrorCodesEnum::CLIENT_ERROR,
        errors: $this->errors,
      );
    }

    return new ApiResponseDto(
      status: $this->status,
      message: $this->getMessage(),
      error: $errorDto,
    );
  }

  public static function badRequest(string $message = 'Solicitud incorrecta.'): self
  {
    return new self(Response::HTTP_BAD_REQUEST, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::BAD_REQUEST);
  }

  public static function conflict(string $message = 'Conflicto con el estado actual del recurso.'): self
  {
    return new self(Response::HTTP_CONFLICT, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::CLIENT_ERROR);
  }

  public static function unauthorized(
    string $message = 'No autenticado.',
    ?array $errors = null
  ): self {
    return new self(Response::HTTP_UNAUTHORIZED, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::UNAUTHORIZED, $errors);
  }

  public static function forbidden(string $message = 'No tiene los permisos suficientes para realizar esta acción.'): self
  {
    return new self(Response::HTTP_FORBIDDEN, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::FORBIDDEN);
  }

  public static function notFound(string $message = 'Recurso no encontrado.'): self
  {
    return new self(Response::HTTP_NOT_FOUND, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::NOT_FOUND);
  }

  public static function unprocessableEntity(string $message = 'La entidad no pudo ser procesada.'): self
  {
    return new self(Response::HTTP_UNPROCESSABLE_ENTITY, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::CLIENT_ERROR);
  }

  public static function validationException(
    string $message = 'Los datos proporcionados no son válidos.',
    ?array $errors = null
  ): self {
    return new self(Response::HTTP_UNPROCESSABLE_ENTITY, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::VALIDATION_ERROR, $errors);
  }

  public static function tooManyRequests(string $message = 'Demasiadas solicitudes.'): self
  {
    return new self(Response::HTTP_TOO_MANY_REQUESTS, $message, ResponseStatusEnum::ERROR, ErrorCodesEnum::CLIENT_ERROR);
  }

  public static function internalServer(
    string $message = 'Error interno del servidor.',
    ?\Throwable $exception = null,
  ): self {
    return new self(Response::HTTP_INTERNAL_SERVER_ERROR, $message, ResponseStatusEnum::ERROR, ErrorCodesEnum::SERVER_ERROR, null, $exception);
  }

  public static function notImplemented(string $message = 'Funcionalidad no implementada.'): self
  {
    return new self(Response::HTTP_NOT_IMPLEMENTED, $message, ResponseStatusEnum::ERROR, ErrorCodesEnum::NOT_IMPLEMENTED);
  }

  public static function badGateway(string $message = 'Respuesta de gateway inválida.'): self
  {
    return new self(Response::HTTP_BAD_GATEWAY, $message, ResponseStatusEnum::ERROR, ErrorCodesEnum::SERVER_ERROR);
  }

  public static function serviceUnavailable(string $message = 'Servicio no disponible temporalmente.'): self
  {
    return new self(Response::HTTP_SERVICE_UNAVAILABLE, $message, ResponseStatusEnum::ERROR, ErrorCodesEnum::SERVER_ERROR);
  }

  public static function corsError(string $message = 'No permitido por CORS.', array $allowedOrigins = []): self
  {
    return new self(Response::HTTP_FORBIDDEN, $message, ResponseStatusEnum::FAIL, ErrorCodesEnum::CORS_ERROR, ['allowedOrigins' => $allowedOrigins]);
  }
}
