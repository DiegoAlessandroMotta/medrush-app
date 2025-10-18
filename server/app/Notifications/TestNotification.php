<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use NotificationChannels\Fcm\FcmChannel;
use NotificationChannels\Fcm\FcmMessage;
use NotificationChannels\Fcm\Resources\Notification as FcmNotification;

class TestNotification extends Notification implements ShouldQueue
{
  use Queueable;

  /**
   * @var string[]
   */
  protected array $channels = [];

  public function __construct(array $channels = [
    FcmChannel::class,
    'mail'
  ])
  {
    $this->channels = $channels;
  }

  public function via(object $notifiable): array
  {
    return $this->channels;
  }

  public function toFcm($notifiable): FcmMessage
  {
    return (new FcmMessage(notification: new FcmNotification(
      title: 'Account Activated',
      body: 'Your account has been activated.',
      // image: ''
    )))
      ->data(['data1' => 'value', 'data2' => 'value2']);
  }

  public function toMail(object $notifiable): MailMessage
  {
    return (new MailMessage)
      ->line('The introduction to the notification.')
      ->action('Notification Action', url('/'))
      ->line('Thank you for using our application!');
  }
}
