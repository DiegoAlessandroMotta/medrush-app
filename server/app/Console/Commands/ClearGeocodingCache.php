<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class ClearGeocodingCache extends Command
{
  protected $signature = 'geocoding:clear-cache {--pattern=geocoding:* : Patrón de claves a limpiar}';

  protected $description = 'Limpia el caché de geocodificación';

  public function handle()
  {
    $pattern = $this->option('pattern');

    $this->info("Limpiando caché con patrón: {$pattern}");

    $store = Cache::getStore();

    if (method_exists($store, 'flush')) {
      $this->warn('Nota: Esto limpiará todo el caché. Para limpiar solo claves específicas, considera usar Redis.');
      if ($this->confirm('¿Estás seguro de que quieres limpiar todo el caché?')) {
        Cache::flush();
        $this->info('Caché limpiado completamente.');
      }
    } else {
      $this->error('El driver de caché actual no soporta limpieza selectiva.');
      $this->info('Considera usar Redis como driver de caché para mejor control.');
    }

    return 0;
  }
}
