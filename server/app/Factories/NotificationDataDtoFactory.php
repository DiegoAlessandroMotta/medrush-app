<?php

namespace App\Factories;

use App\DTOs\Jobs\NotificationDataDto;
use App\Enums\Notifications\NotificationChannelsEnum;
use App\Enums\NotificationTypeEnum;

class NotificationDataDtoFactory
{
  /** @param array<NotificationChannelsEnum>|null $channels */
  public static function create(
    NotificationTypeEnum $type,
    string $title,
    ?string $message = null,
    ?array $details = null,
    ?array $channels = null,
    mixed $extra = null,
  ): NotificationDataDto {
    return new NotificationDataDto(
      type: $type,
      title: $title,
      message: $message,
      details: $details,
      channels: $channels,
      extra: $extra,
    );
  }

  /** @param array<NotificationChannelsEnum>|null $channels */
  public static function info(
    string $title,
    ?string $message = null,
    ?array $details = null,
    ?array $channels = null,
    mixed $extra = null,
  ): NotificationDataDto {
    return new NotificationDataDto(
      type: NotificationTypeEnum::INFO,
      title: $title,
      message: $message,
      details: $details,
      channels: $channels,
      extra: $extra,
    );
  }

  /** @param array<NotificationChannelsEnum>|null $channels */
  public static function success(
    string $title,
    ?string $message = null,
    ?array $details = null,
    ?array $channels = null,
    mixed $extra = null,
  ): NotificationDataDto {
    return new NotificationDataDto(
      type: NotificationTypeEnum::SUCCESS,
      title: $title,
      message: $message,
      details: $details,
      channels: $channels,
      extra: $extra,
    );
  }

  /** @param array<NotificationChannelsEnum>|null $channels */
  public static function warning(
    string $title,
    ?string $message = null,
    ?array $details = null,
    ?array $channels = null,
    mixed $extra = null,
  ): NotificationDataDto {
    return new NotificationDataDto(
      type: NotificationTypeEnum::WARNING,
      title: $title,
      message: $message,
      details: $details,
      channels: $channels,
      extra: $extra,
    );
  }

  /** @param array<NotificationChannelsEnum>|null $channels */
  public static function error(
    string $title = 'Error',
    ?string $message = 'Ha ocurrido un error inesperado.',
    ?array $details = null,
    ?array $channels = null,
    mixed $extra = null,
  ): NotificationDataDto {
    $defaultErrorChannels = [
      NotificationChannelsEnum::FCM_CHANNEL,
      NotificationChannelsEnum::DATABASE,
    ];

    $effectiveChannels = $channels ?? $defaultErrorChannels;

    return new NotificationDataDto(
      type: NotificationTypeEnum::ERROR,
      title: $title,
      message: $message,
      details: $details,
      channels: $effectiveChannels,
      extra: $extra,
    );
  }
}
