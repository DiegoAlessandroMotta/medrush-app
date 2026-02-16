<?php

namespace App\Listeners\Fcm;

use Arr;
use Illuminate\Notifications\Events\NotificationFailed;
use NotificationChannels\Fcm\FcmChannel;

class DeleteExpiredNotificationTokens
{
  public function handle(NotificationFailed $event): void
  {
    if ($event->channel == FcmChannel::class) {

      $report = Arr::get($event->data, 'report');

      if ($report === null) {
        return;
      }

      $target = $report->target();

      if ($target === null) {
        return;
      }

      $event->notifiable->fcmDeviceTokens()
        ->where('token', $target->value())
        ->delete();
    }
  }
}
