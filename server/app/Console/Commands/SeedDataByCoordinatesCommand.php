<?php

namespace App\Console\Commands;

use App\Casts\AsPoint;
use App\Helpers\GeoHelper;
use App\Models\Farmacia;
use App\Models\Pedido;
use App\Models\User;
use Illuminate\Console\Command;

class SeedDataByCoordinatesCommand extends Command
{
  protected $signature = 'app:seed {--lat=} {--lng=} {--radius=5} {--farmacias=5} {--repartidores=10} {--pedidos=50}';
  protected $description = 'Genera datos fake de farmacias, repartidores y pedidos en coordenadas específicas. Uso: --lat=LATITUD --lng=LONGITUD [opciones]';

  public function handle()
  {
    $latitude = $this->option('lat');
    $longitude = $this->option('lng');

    if ($latitude === null || $longitude === null) {
      $this->error('Debes proporcionar las coordenadas con --lat y --lng');
      $this->info('Ejemplo: php artisan app:seed --lat=-12.0464 --lng=-77.0428');
      return 1;
    }

    $latitude = (float) $latitude;
    $longitude = (float) $longitude;
    $radius = (float) $this->option('radius');
    $farmaciaCount = (int) $this->option('farmacias');
    $repartidorCount = (int) $this->option('repartidores');
    $pedidoCount = (int) $this->option('pedidos');

    if ($latitude < -90 || $latitude > 90) {
      $this->error('La latitud debe estar entre -90 y 90');
      return 1;
    }

    if ($longitude < -180 || $longitude > 180) {
      $this->error('La longitud debe estar entre -180 y 180');
      return 1;
    }
    $centerPoint = [
      'latitude' => $latitude,
      'longitude' => $longitude,
    ];

    $this->info("Creando {$farmaciaCount} farmacias...");
    $farmacias = $this->createFarmacias($centerPoint, $radius, $farmaciaCount);
    $this->info("{$farmaciaCount} farmacias creadas exitosamente");

    $this->info("Creando {$repartidorCount} repartidores...");
    $this->createRepartidores($farmacias, $repartidorCount);
    $this->info("{$repartidorCount} repartidores creados exitosamente");

    $this->info("Creando {$pedidoCount} pedidos...");
    $this->createPedidos($farmacias, $centerPoint, $radius, $pedidoCount);
    $this->info("{$pedidoCount} pedidos creados exitosamente");

    $this->newLine();
    $this->info("Datos generados:");
    $this->table(
      ['Tipo', 'Cantidad'],
      [
        ['Farmacias', $farmaciaCount],
        ['Repartidores', $repartidorCount],
        ['Pedidos', $pedidoCount],
      ]
    );

    return 0;
  }

  private function createFarmacias(array $centerPoint, float $radius, int $count): array
  {
    $farmacias = [];

    for ($i = 0; $i < $count; $i++) {
      $randomLocation = GeoHelper::generateRandomPointInRadius($centerPoint, $radius);

      $farmacia = Farmacia::factory()->create([
        'ubicacion' => AsPoint::pointFromArray($randomLocation),
        'ciudad' => $this->getCityFromCoordinates($centerPoint),
        'estado_region' => $this->getStateFromCoordinates($centerPoint),
      ]);

      $farmacias[] = $farmacia;

      if (($i + 1) % 10 === 0) {
        $this->output->write('.');
      }
    }

    $this->newLine();
    return $farmacias;
  }

  private function createRepartidores(array $farmacias, int $count): array
  {
    $repartidores = [];

    for ($i = 0; $i < $count; $i++) {
      $farmacia = rand(0, 2) === 0 ? $farmacias[array_rand($farmacias)] : null;

      $user = User::factory()->repartidor()->create();
      $perfilRepartidor = $user->perfilRepartidor;

      if ($farmacia) {
        $perfilRepartidor->farmacia_id = $farmacia->id;
        $perfilRepartidor->save();
      }

      $repartidores[] = $perfilRepartidor;

      if (($i + 1) % 10 === 0) {
        $this->output->write('.');
      }
    }

    $this->newLine();
    return $repartidores;
  }

  private function createPedidos(array $farmacias, array $centerPoint, float $radius, int $count): array
  {
    $pedidos = [];

    for ($i = 0; $i < $count; $i++) {
      $farmacia = $farmacias[array_rand($farmacias)];
      $deliveryLocation = GeoHelper::generateRandomPointInRadius($centerPoint, $radius);

      $pedido = Pedido::factory()->create([
        'farmacia_id' => $farmacia->id,
        'ubicacion_recojo' => $farmacia->ubicacion,
        'ubicacion_entrega' => AsPoint::pointFromArray($deliveryLocation),
        'ciudad_entrega' => $this->getCityFromCoordinates($centerPoint),
        'estado_region_entrega' => $this->getStateFromCoordinates($centerPoint),
      ]);

      $pedidos[] = $pedido;

      if (($i + 1) % 10 === 0) {
        $this->output->write('.');
      }
    }

    $this->newLine();
    return $pedidos;
  }

  private function getCityFromCoordinates(array $centerPoint): string
  {
    if (
      $centerPoint['latitude'] >= -12.2 && $centerPoint['latitude'] <= -12.0 &&
      $centerPoint['longitude'] >= -77.2 && $centerPoint['longitude'] <= -76.8
    ) {
      return collect(['San Isidro', 'Miraflores', 'San Borja', 'Surco', 'La Molina', 'Jesús María'])->random();
    }

    return collect(['Centro', 'Norte', 'Sur', 'Este', 'Oeste'])->random() . ' City';
  }

  private function getStateFromCoordinates(array $centerPoint): string
  {
    if ($centerPoint['latitude'] >= -12.5 && $centerPoint['latitude'] <= -11.5) {
      return 'Lima';
    }

    return 'Región Central';
  }
}
