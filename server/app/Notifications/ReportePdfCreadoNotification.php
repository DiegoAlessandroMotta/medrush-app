<?php

namespace App\Notifications;

use App\DTOs\Jobs\NotificationDataDto;
use App\Helpers\ArrayToMarkdown;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;
use NotificationChannels\Fcm\FcmMessage;
use NotificationChannels\Fcm\Resources\Notification as FcmNotification;

class ReportePdfCreadoNotification extends Notification implements ShouldQueue
{
  use Queueable;

  /** @var NotificationDataDto */
  private NotificationDataDto $notificationData;

  public function __construct(
    NotificationDataDto $notificationData,
  ) {
    $this->notificationData = $notificationData;
  }

  public function via(object $notifiable): array
  {
    return $this->notificationData->getChannels();
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
      ]
    );
  }

  public function toArray(object $notifiable): array
  {
    return [
      'type' => $this->notificationData->type->value,
      'type' => $this->notificationData->type->value,
      'title' => $this->notificationData->title,
      'message' => $this->notificationData->message,
      'details' => ArrayToMarkdown::convert($this->notificationData->details),
      'extra' => $this->notificationData->extra,
    ];
  }
}
