<?php

namespace App\Providers;

use App\Policies\GoogleApiServicePolicy;
use App\Policies\GoogleApiUsagePolicy;
use App\Policies\SignedUrlPolicy;
use Gate;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
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
    $this->configureRateLimiters();
    $this->configureGates();
  }

  protected function configureGates(): void
  {
    Gate::define('getSignedUrlCsvTemplate', [SignedUrlPolicy::class, 'getSignedUrlCsvTemplate']);
    Gate::define('reverseGeocode', [GoogleApiServicePolicy::class, 'reverseGeocode']);
    Gate::define('getDirectionsWithWaypoints', [GoogleApiServicePolicy::class, 'getDirectionsWithWaypoints']);
    Gate::define('getRouteInfo', [GoogleApiServicePolicy::class, 'getRouteInfo']);
    Gate::define('viewUsageStats', [GoogleApiUsagePolicy::class, 'viewUsageStats']);
  }

  protected function configureRateLimiters(): void
  {
    RateLimiter::for('client-errors-report', function (Request $request) {
      return [
        Limit::perMinute(30)->by($request->ip()),
        Limit::perDay(500)->by($request->ip()),
      ];
    });
  }
}
