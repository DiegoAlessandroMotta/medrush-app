<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class ClearGeocodingCache extends Command
{
  protected $signature = 'cache:clear-geo
                         {--type=all : Tipo de caché a limpiar: geocoding, directions, all}
                         {--pattern=* : Patrón específico de claves a limpiar}';

  protected $description = 'Limpia el caché de geocodificación y direcciones';

  public function handle()
  {
    $type = $this->option('type');
    $patterns = $this->option('pattern');

    if (!empty($patterns)) {
      foreach ($patterns as $pattern) {
        $this->info("Limpiando caché con patrón: {$pattern}");
      }
    } else {
      $this->clearByType($type);
    }

    return 0;
  }

  private function clearByType(string $type): void
  {
    switch ($type) {
      case 'geocoding':
        $this->info('Limpiando caché de geocodificación...');
        $this->clearWithPattern('geocoding:*');
        break;

      case 'directions':
        $this->info('Limpiando caché de direcciones...');
        $this->clearWithPattern('directions:*');
        break;

      case 'all':
      default:
        $this->info('Limpiando todo el caché de georeferenciación...');
        $this->clearWithPattern('geocoding:*');
        $this->clearWithPattern('directions:*');
        break;
    }
  }

  private function clearWithPattern(string $pattern): void
  {
    $store = Cache::getStore();

    if (method_exists($store, 'flush')) {
      $this->warn("Nota: El driver actual no soporta limpieza por patrón.");
      $this->warn("Esto limpiará TODO el caché. Para limpieza selectiva, usa Redis.");

      if ($this->confirm("¿Limpiar todo el caché? (patrón: {$pattern})")) {
        Cache::flush();
        $this->info('Caché limpiado completamente.');
      } else {
        $this->info('Operación cancelada.');
      }
    } else {
      $this->error('El driver de caché actual no soporta limpieza.');
      $this->info('Considera usar Redis como driver de caché para mejor control.');
    }
  }
}
