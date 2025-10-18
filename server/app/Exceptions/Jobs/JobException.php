<?php

namespace App\Exceptions\Jobs;

use App\DTOs\Jobs\NotificationDataDto;
use App\Enums\NotificationTypeEnum;
use Exception;
use Throwable;

class JobException extends Exception
{
  public readonly NotificationTypeEnum $notificationType;
  public readonly array $details;
  public readonly ?Throwable $previous;

  public function __construct(
    string $message,
    array $details = [],
    ?Throwable $previous = null,
  ) {
    parent::__construct($message, 0, $previous);
    $this->notificationType = NotificationTypeEnum::ERROR;
    $this->details = $details;
    $this->previous = $previous;
  }

  public function toNotification(?string $title = "Ha ocurrido un error"): NotificationDataDto
  {
    return new NotificationDataDto(
      type: $this->notificationType,
      title: $title,
      message: $this->message,
      details: $this->details,
    );
  }
}
