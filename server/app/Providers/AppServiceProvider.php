<?php

namespace App\Providers;

use App\Policies\DownloadPolicy;
use App\Policies\SignedUrlPolicy;
use Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
  public function register(): void
  {
    if ($this->app->environment('local') && class_exists(\Laravel\Telescope\TelescopeServiceProvider::class)) {
      $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
      $this->app->register(TelescopeServiceProvider::class);
    }
  }

  public function boot(): void
  {
    Gate::define('getSignedUrlCsvTemplate', [SignedUrlPolicy::class, 'getSignedUrlCsvTemplate']);
  }
}
