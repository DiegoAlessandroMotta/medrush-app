<?php

namespace App\Enums\Notifications;

use NotificationChannels\Fcm\FcmChannel;

enum NotificationChannelsEnum: string
{
  case FCM_CHANNEL = FcmChannel::class;
  case DATABASE = 'database';

  /**
   * @param array<NotificationChannelsEnum> $channels
   * @return array<string>
   */
  public static function getValues(array $channels): array
  {
    return array_column($channels, 'value');
  }
}
