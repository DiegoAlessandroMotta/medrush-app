<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
  $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('reports:cleanup-old-pdfs')
  ->daily()
  ->at('02:00')
  ->withoutOverlapping()
  ->runInBackground();

Schedule::command('pedidos:cleanup-old-files')
  ->weekly()
  ->sundays()
  ->at('03:00')
  ->withoutOverlapping()
  ->runInBackground();
