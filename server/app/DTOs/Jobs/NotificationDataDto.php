<?php

namespace App\DTOs\Jobs;

use App\Enums\Notifications\NotificationChannelsEnum;
use App\Enums\NotificationTypeEnum;

class NotificationDataDto
{
  /**
   * @var array<NotificationChannelsEnum>
   */
  public static array $defaultChannels = [
    NotificationChannelsEnum::FCM_CHANNEL,
    NotificationChannelsEnum::DATABASE,
  ];

  /** @var array<NotificationChannelsEnum> */
  public array $channels;

  /** @param array<NotificationChannelsEnum> $channels */
  public function __construct(
    public NotificationTypeEnum $type,
    public string $title,
    public ?string $message = null,
    public ?array $details = null,
    ?array $channels = null,
    public mixed $extra = null,
  ) {
    $this->channels = $channels ?? self::$defaultChannels;
  }

  public function getChannels(): array
  {
    return NotificationChannelsEnum::getValues($this->channels);
  }
}
