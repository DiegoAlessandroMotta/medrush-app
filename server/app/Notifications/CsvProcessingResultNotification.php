<?php

namespace App\Notifications;

use App\DTOs\Jobs\NotificationDataDto;
use App\Enums\Notifications\NotificationChannelsEnum;
use App\Enums\NotificationTypeEnum;
use App\Factories\NotificationDataDtoFactory;
use App\Helpers\NotificationMessageBuilder;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Fcm\FcmMessage;
use NotificationChannels\Fcm\Resources\Notification as FcmNotification;

class CsvProcessingResultNotification extends Notification implements ShouldQueue
{
  use Queueable;

  /** @var NotificationDataDto */
  private NotificationDataDto $notificationData;

  /**
   * @param array<NotificationChannelsEnum> $channels
   * @param int $processedRecords
   * @param int $successRecords
   * @param int $failedRecords
   * @param array $errorDetails
   */
  public function __construct(
    array $channels = [],
    int $processedRecords = 0,
    int $successRecords = 0,
    int $failedRecords = 0,
    array $errorDetails = [],
  ) {
    $type = NotificationTypeEnum::INFO;
    $title = 'Procesamiento de Archivo CSV';
    $message = 'Tu archivo CSV fue procesado';
    $detailsMarkdown = '';

    if ($failedRecords === 0) {
      $type = NotificationTypeEnum::SUCCESS;
      $message = 'Tu archivo CSV ha sido procesado exitosamente.';
      $detailsMarkdown = NotificationMessageBuilder::buildCsvSuccessMessage(
        $processedRecords,
        $successRecords
      );
    } elseif ($successRecords === 0 && $processedRecords > 0) {
      $type = NotificationTypeEnum::ERROR;
      $title = 'Error de Procesamiento de CSV';
      $message = 'No pudimos procesar tu archivo CSV debido a un error interno. Por favor, inténtalo de nuevo más tarde o contacta a soporte.';
      $detailsMarkdown = NotificationMessageBuilder::buildCsvErrorMessage(
        'nuestro equipo de soporte'
      );
    } elseif ($failedRecords > 0) {
      $type = NotificationTypeEnum::WARNING;
      $message = 'Tu archivo CSV fue procesado, pero se encontraron algunos errores.';
      $detailsMarkdown = NotificationMessageBuilder::buildCsvWarningMessage(
        $processedRecords,
        $successRecords,
        $failedRecords,
        $errorDetails
      );
    } else {
      $detailsMarkdown = <<<MARKDOWN
El proceso de tu archivo CSV ha finalizado.

*   Registros procesados: {$processedRecords}
*   Registros con éxito: {$successRecords}
*   Registros con errores: {$failedRecords}

No se encontraron errores graves.
MARKDOWN;
    }

    $this->notificationData = NotificationDataDtoFactory::create(
      type: $type,
      title: $title,
      message: $message,
      details: ['markdown' => $detailsMarkdown],
      channels: $channels,
      extra: [
        'processedRecords' => $processedRecords,
        'successRecords' => $successRecords,
        'failedRecords' => $failedRecords,
        'errorDetails' => $errorDetails,
      ],
    );
  }

  /**
   * @return array<int, string>
   */
  public function via(object $notifiable): array
  {
    return NotificationChannelsEnum::getValues($this->notificationData->channels);
  }

  public function toFcm(object $notifiable): FcmMessage
  {
    $fcmNotification = new FcmNotification(
      title: $this->notificationData->title,
      body: $this->notificationData->message,
    );

    return new FcmMessage(
      notification: $fcmNotification,
      data: [
        'type' => $this->notificationData->type->value,
        'title' => $this->notificationData->title,
        'message' => $this->notificationData->message,
        'details' => $this->notificationData->details['markdown'] ?? null,
        'extra' => $this->notificationData->extra,
      ]
    );
  }

  /**
   * @return array<string, mixed>
   */
  public function toArray(object $notifiable): array
  {
    return [
      'type' => $this->notificationData->type->value,
      'title' => $this->notificationData->title,
      'message' => $this->notificationData->message,
      'details' => $this->notificationData->details['markdown'] ?? null,
      'extra' => $this->notificationData->extra,
    ];
  }
}
